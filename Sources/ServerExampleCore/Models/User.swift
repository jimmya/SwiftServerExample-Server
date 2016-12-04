import Foundation
import MongoKitten
import JWT
import SwiftyJSON

struct UserSmall {
    let id: String
    let name: String
    
    var dictionaryValue: [String: Any]  {
        return ["id": id,
                "name": name]
    }
    
    var documentValue: Document {
        var objectId = ObjectId()
        do {
            objectId = try ObjectId(id)
        } catch {}
        return  [
            "_id": .objectId(objectId),
            "name": .string(name)
        ]
    }
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
    
    init?(document: Document) {
        guard let id = document["_id"].objectIdValue?.hexString,
            let name = document["name"].stringValue else {
                return nil
        }
        self.id = id
        self.name = name
    }
}

struct User {
    
    let id: String
    let name: String
    var password: String
    let email: String
    var sessions: Document
    
    var dictionaryValue: [String: Any]  {
        return ["id": id,
                "name": name,
                "email": email]
    }
    
    var documentValue: Document {
        var objectId = ObjectId()
        do {
            objectId = try ObjectId(id)
        } catch {}
        return  [
            "_id": .objectId(objectId),
            "name": .string(name),
            "password": .string(password),
            "email": .string(email),
            "sessions": .document(sessions)
        ]
    }
    
    var token: String? {
        guard let signingData = ServerExampleSettings.signingSecret.data(using: .utf8) else {
            return nil
        }
        return JWT.encode(.hs256(signingData)) { builder in
            builder.issuer = id
            builder.issuedAt = Date()
            builder.expiration = Date().addingTimeInterval(ServerExampleSettings.tokenValidDuration)
            builder["name"] = name
        }
    }
    
    init(id: String = ObjectId().hexString, name: String, password: String, email: String) {
        self.id = id
        self.name = name
        self.password = password
        self.email = email
        self.sessions = Document(array: [])
    }
    
    init?(document: Document) {
        guard let id = document["_id"].objectIdValue?.hexString,
            let name = document["name"].stringValue,
            let password = document["password"].stringValue,
            let email = document["email"].stringValue else {
                return nil
        }
        self.id = id
        self.name = name
        self.password = password
        self.email = email
        self.sessions = document["sessions"].document
    }
    
    init?(json: JSON) {
        guard let name = json["name"].string,
            let email = json["email"].string,
            let password = json["password"].string else {
                return nil
        }
        self.id = ObjectId().hexString
        self.name = name
        self.email = email
        self.password = password
        self.sessions = Document(array: [])
    }
    
    init?(dictionary: [String: String]) {
        guard let name = dictionary["name"]?.removingPercentEncoding,
            let email = dictionary["email"]?.removingPercentEncoding,
            let password = dictionary["password"]?.removingPercentEncoding else {
                return nil
        }
        self.id = ObjectId().hexString
        self.name = name
        self.email = email
        self.password = password
        self.sessions = Document(array: [])
    }
}
