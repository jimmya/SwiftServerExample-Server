import Kitura
import Swinject

class BaseController {
    
    let dependencyContainer: Container
    
    required init(router: Router, dependencyContainer: Container) {
        self.dependencyContainer = dependencyContainer
        registerRoutes(router: router)
    }
    
    func registerRoutes(router: Router) {
        
    }
}
