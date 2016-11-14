import PackageDescription

let package = Package(
    name: "SwiftServerExample-Server",
    targets : [
        Target(name: "Server", dependencies: [.Target(name: "ServerExampleCore")]),
        Target(name: "ServerExampleCore")
    ],
    dependencies: [
        .Package(url: "https://github.com/IBM-Swift/Kitura.git", majorVersion: 1, minor: 1),
        .Package(url: "https://github.com/IBM-Swift/HeliumLogger.git", majorVersion: 1, minor: 1)
    ]
)
