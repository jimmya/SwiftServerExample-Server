import PackageDescription

let package = Package(
    name: "SwiftServerExample-Server",
    targets : [
        Target(name: "Server", dependencies: [.Target(name: "ServerExampleCore")]),
        Target(name: "ServerExampleCore")
    ],
    dependencies: [
        .Package(url: "https://github.com/IBM-Swift/Kitura.git", majorVersion: 1, minor: 3),
        .Package(url: "https://github.com/IBM-Swift/HeliumLogger.git", majorVersion: 1, minor: 3),
        .Package(url: "https://github.com/OpenKitten/MongoKitten.git", majorVersion: 1, minor: 7),
        .Package(url: "https://github.com/IBM-Swift/Kitura-StencilTemplateEngine.git", majorVersion: 1, minor: 3),
        .Package(url: "https://github.com/IBM-Swift/Kitura-Credentials.git", majorVersion: 1, minor: 3),
        .Package(url: "https://github.com/IBM-Swift/Kitura-Request.git", majorVersion: 0, minor: 4),
        .Package(url: "https://github.com/jimmya/JSONWebToken.swift.git", majorVersion: 2, minor: 0),
        .Package(url: "https://github.com/jimmya/Swinject.git", majorVersion: 2)
    ]
)
