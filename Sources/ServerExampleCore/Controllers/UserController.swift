import Foundation
import Kitura
import KituraRequest
import MongoKitten
import LoggerAPI
import SwiftyJSON
import Dispatch
import Credentials
import JWT
import SwiftExampleCommon

final class UserController: BaseController {
    
    fileprivate var usersRepository: UsersRepositoryProtocol? {
        return dependencyContainer.resolve(UsersRepositoryProtocol.self)
    }
    fileprivate let queue = DispatchQueue(label: "com.swiftserversample.users")
    
    override func registerRoutes(router: Router) {
        super.registerRoutes(router: router)
        
        router.all("/v1/user", middleware: BodyParser())
        router.all("/resetpassword", middleware: BodyParser())
        
        router.post("/v1/user", handler: createUser)
        router.post("/v1/user/login", handler: loginUser)
        router.post("/v1/user/resetpassword", handler: resetPassword)
        
        router.get("/resetpassword", handler: getResetPassword)
        router.post("/resetpassword", handler: postResetPassword)
    }
}

extension UserController {
    
    func createUser(request: RouterRequest,
                    response: RouterResponse,
                    next: @escaping () -> Void) throws {
        defer {
            next()
        }
        
        guard let parameters = request.urlEncoded,
            let user = User(dictionary: parameters) else {
                response.status(.badRequest)
                return
        }
        
        queue.sync {
            usersRepository?.createUser(user: user) { (user, error) in
                if let responseJSON = responseJSON(forUser: user) {
                    response.status(.OK).send(json: responseJSON)
                } else {
                    Log.error(error?.message ?? "Unkown error occured creating user")
                    response.status(error?.statusCode ?? .internalServerError)
                }
            }
        }
    }
    
    func loginUser(request: RouterRequest,
                   response: RouterResponse,
                   next: @escaping () -> Void) throws {
        defer {
            next()
        }
        
        guard let parameters = request.urlEncoded else {
            response.status(.badRequest)
            return
        }
        
        queue.sync {
            usersRepository?.loginUser(email: parameters["email"]?.removingPercentEncoding, password: parameters["password"]) { (user, error) in
                if let responseJSON = responseJSON(forUser: user) {
                    response.status(.OK).send(json: responseJSON)
                } else {
                    Log.error(error?.message ?? "Unkown error occured creating user")
                    response.status(error?.statusCode ?? .internalServerError)
                }
            }
        }
    }
    
    func resetPassword(request: RouterRequest,
                       response: RouterResponse,
                       next: @escaping () -> Void) throws {
        defer {
            next()
        }
        
        guard let parameters = request.urlEncoded else {
            response.status(.badRequest)
            return
        }
        
        queue.sync {
            usersRepository?.getUser(email: parameters["email"]?.removingPercentEncoding, completion: { (user, error) in
                guard let user = user else {
                    Log.error(error?.message ?? "Unkown error occured requesting password reset")
                    response.status(error?.statusCode ?? .internalServerError)
                    return
                }
                usersRepository?.addUserSession(user: user) { (token, error) in
                    guard let token = token else {
                        Log.error(error?.message ?? "Unkown error occured requesting password reset")
                        response.status(error?.statusCode ?? .internalServerError)
                        return
                    }
                    
                    let apiCredentials = "api:\(ServerExampleSettings.mailAPIKey)".toBase64()
                    KituraRequest.request(.post, ServerExampleSettings.mailAPIUrlString, parameters: [
                        "from": "Save My Bike <noreply@onnozelheid.nl>",
                        "to": "\(user.name) <\(user.email)>",
                        "subject": "Save My Bike password reset",
                        "html": "Hey \(user.name),<br /><br />A request to change your password has been made on Save My Bike. If you want to change your password, visit the link below.<br />If you'd like to keep your current password, just ignore this email.<br /><br /><a href=\"\(ServerExampleSettings.host)/resetpassword?email=\(user.email)%26token=\(token)\">Reset your password here.</a><br /><br />Have a nice day!<br /><br />~The Save My Bike team"
                        ], encoding: FormURLEncoding.default, headers: [
                            "authorization": "Basic \(apiCredentials)"
                        ]).response({ (request, mailResponse, data, error) in
                            if mailResponse?.statusCode == .OK {
                                response.status(.OK)
                            } else {
                                Log.error("Error sending password reset mail: \(error)")
                                response.status(.internalServerError)
                            }
                        })
                }
            })
        }
    }
    
    func responseJSON(forUser user: User?) -> JSON? {
        guard let user = user,
            let token = user.token else {
                return nil
        }
        let responseObject: [String: Any] = [
            "user": user.dictionaryValue,
            "token": token,
            "type": "Bearer",
            "issued": Date().timeIntervalSince1970,
            "expires": Date().addingTimeInterval(ServerExampleSettings.tokenValidDuration).timeIntervalSince1970,
            "expiresIn": ServerExampleSettings.tokenValidDuration
        ]
        return JSON(responseObject)
    }
    
    func getResetPassword(request: RouterRequest,
                          response: RouterResponse,
                          next: @escaping () -> Void) throws {
        defer {
            next()
        }
        
        queue.sync {
            usersRepository?.getUserSession(email: request.queryParameters["email"], token: request.queryParameters["token"]) { (user, token, error) in
                if let user = user, let token = token {
                    do {
                        try response.render("password", context: ["email": user.email, "token": token, "message": "Please enter a new password."]).end()
                    } catch {
                        response.status(.internalServerError)
                    }
                } else {
                    do {
                        try response.render("password", context: ["invalid": true]).end()
                    } catch {
                        response.status(.internalServerError)
                    }
                }
            }
        }
    }
    
    func postResetPassword(request: RouterRequest,
                           response: RouterResponse,
                           next: @escaping () -> Void) throws {
        defer {
            next()
        }
        
        var errorMessage: String?
        guard let parameters = request.urlEncoded,
            let email = request.queryParameters["email"],
            let token = request.queryParameters["token"],
            let password = parameters["password"],
            let passwordConfirm = parameters["passwordConfirm"] else {
                return try getResetPassword(request: request, response: response, next: next)
        }
        
        queue.sync {
            usersRepository?.getUserSession(email: email, token: token) { (user, token, error) in
                if let user = user, let _ = token {
                    if password != passwordConfirm {
                        errorMessage = "Passwords do not match"
                    } else if password.characters.count < 4 {
                        errorMessage = "Password is too short"
                    } else {
                        var newUser = user
                        newUser.sessions = Document()
                        if let encryptedPassword = password.encrypt(key: ServerExampleSettings.passwordEncryptionKey) {
                            newUser.password = encryptedPassword
                        }
                        usersRepository?.updateUser(id: user.id, user: newUser) { (user, error) in
                            if error != nil {
                                errorMessage = "Unable to change password"
                            }
                        }
                    }
                } else {
                    errorMessage = "Unable to change password"
                }
            }
        }
        
        if let errorMessage = errorMessage {
            try response.render("password", context: ["message": errorMessage]).end()
        } else {
            try response.render("password", context: ["success": true]).end()
        }
    }
}
