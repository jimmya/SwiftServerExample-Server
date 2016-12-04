import Foundation
import Kitura
import KituraNet
import MongoKitten
import LoggerAPI

protocol UsersRepositoryProtocol {
    func createUser(user: User, completion: (User?, RepositoryError?) -> Void)
    func loginUser(email: String?, password: String?, completion: (User?, RepositoryError?) -> Void)
    func getUser(email: String?, completion: (User?, RepositoryError?) -> Void)
    func addUserSession(user: User, completion: (String?, RepositoryError?) -> Void)
    func getUserSession(email: String?, token: String?, completion: (User?, String?, RepositoryError?) -> Void)
    func updateUser(id: String, user: User, completion: (User?, RepositoryError?) -> Void)
}

final class UsersRepository: UsersRepositoryProtocol {
    
    var usersCollection: MongoKitten.Collection?
    var leasesCollection: MongoKitten.Collection?
    
    init(database: Database) {
        usersCollection = database["users"]
        leasesCollection = database["leases"]
    }
}

extension UsersRepository {
    
    func createUser(user: User, completion: (User?, RepositoryError?) -> Void) {
        do {
            if try usersCollection?.findOne(matching: "email" == user.email) != nil {
                completion(nil, RepositoryError.BadRequest("User with this email allready exists"))
                return
            }
            try usersCollection?.insert(user.documentValue)
            completion(user, nil)
        } catch {
            completion(nil, RepositoryError.InternalServerError("Unable to insert document into users"))
        }
    }
    
    func loginUser(email: String?, password: String?, completion: (User?, RepositoryError?) -> Void) {
        guard let password = password,
            let email = email else {
                completion(nil, RepositoryError.BadRequest("Error logging in user: email or password empty"))
                return
        }
        
        do {
            if let userDocument = try usersCollection?.findOne(matching: "email" == email && "password" == password) {
                completion(User(document: userDocument), nil)
                return
            }
            completion(nil, RepositoryError.NotFound("User not found"))
        } catch {
            completion(nil, RepositoryError.InternalServerError("Unable to get users"))
        }
    }
    
    func getUser(email: String?, completion: (User?, RepositoryError?) -> Void) {
        guard let email = email else {
            completion(nil, RepositoryError.BadRequest("Error retrieving user: id or name empty"))
            return
        }
        
        do {
            if let userDocument = try usersCollection?.findOne(matching: "email" == email) {
                completion(User(document: userDocument), nil)
                return
            }
            completion(nil, RepositoryError.NotFound("User not found"))
        } catch {
            completion(nil, RepositoryError.InternalServerError("Unable to get users"))
        }
    }
    
    func addUserSession(user: User, completion: (String?, RepositoryError?) -> Void) {
        let uuidString = "r_\(UUID().uuidString)"
        
        let session: Document = [
            "expires": .dateTime(Date().addingTimeInterval(ServerExampleSettings.tokenValidDuration)),
            "token": .string(uuidString)
        ]
        var userDocument = user.documentValue
        var sessions = userDocument["sessions"].document
        sessions.append(.document(session))
        userDocument["sessions"] = .document(sessions)
        do {
            try usersCollection?.update(matching: user.documentValue, to: userDocument)
            completion(uuidString, nil)
        } catch {
            completion(nil, RepositoryError.InternalServerError("Unable to add session"))
        }
    }
    
    func getUserSession(email: String?, token: String?, completion: (User?, String?, RepositoryError?) -> Void) {
        guard let token = token else {
            completion(nil, nil, RepositoryError.BadRequest("Token is missing"))
            return
        }
        
        getUser(email: email) { (user, error) in
            if let user = user {
                let session = user.sessions.arrayValue.filter({ (value) -> Bool in
                    return token == value["token"].string
                        && Date().timeIntervalSince1970 < value["expires"].dateValue?.timeIntervalSince1970 ?? 0
                })
                if session.count > 0 {
                    completion(user, token, nil)
                } else {
                    completion(nil, nil, RepositoryError.NotFound("No valid session found"))
                }
            } else {
                completion(nil, nil, error)
            }
        }
    }
    
    func updateUser(id: String, user: User, completion: (User?, RepositoryError?) -> Void) {
        do {
            let userIdDocument = try ObjectId(id)
            try usersCollection?.update(matching: "_id" == userIdDocument, to: user.documentValue)
            completion(user, nil)
        } catch {
            completion(nil, RepositoryError.InternalServerError("Unable to update user"))
        }
    }
}
