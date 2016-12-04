import Foundation
import Kitura
import LoggerAPI
import KituraStencil
import Swinject
import MongoKitten

public class ServerExample {
    
    public let router = Router()
    fileprivate let server: Server
    fileprivate let database: Database
    fileprivate let dependencyContainer = Swinject.Container()
    fileprivate let usersRepository: UsersRepository
    fileprivate var controllers: [BaseController] = []
    
    public init() {
        do {
            server = try Server(ServerExampleSettings.mongoConnectionString, automatically: true)
            database = server["socialpark"]
            usersRepository = UsersRepository(database: database)
            
            setupRouter()
            registerDependencies()
            registerControllers()
        } catch {
            Log.error("Unable to connect to MongoDB")
            exit(0)
        }
    }
    
    deinit {
        do {
            try server.disconnect()
        } catch {
            Log.error("Unable to disconnect from MongoDB")
        }
    }
}

fileprivate extension ServerExample {
    
    func setupRouter() {
        router.setDefault(templateEngine: StencilTemplateEngine())
        router.all("/static", middleware: StaticFileServer())
    }
    
    func registerDependencies() {
        dependencyContainer.register(UsersRepositoryProtocol.self) { _ in self.usersRepository }
    }
    
    func registerControllers() {
        controllers.append(UserController(router: router, dependencyContainer: dependencyContainer))
    }
}
