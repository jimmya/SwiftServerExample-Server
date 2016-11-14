import Foundation
import Kitura
import HeliumLogger
import ServerExampleCore

// Initialize HeliumLogger
HeliumLogger.use()

// Initialize SwiftServerExample
let serverExample = ServerExample()

var port: Int = ServerExampleSettings.port

// Add an HTTP server and connect it to the router
Kitura.addHTTPServer(onPort: port, with: serverExample.router)

// Start the Kitura runloop (this call never returns)
Kitura.run()
