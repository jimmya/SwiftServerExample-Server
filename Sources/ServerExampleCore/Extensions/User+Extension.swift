import Foundation
import SwiftExampleCommon

extension User {
    
    var dictionaryValue: [String: Any]?  {
        guard let id = id,
            let name = name,
            let email = email else {
            return nil
        }
        return ["id": id,
                "name": name,
                "email": email]
    }
}
