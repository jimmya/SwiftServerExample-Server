import Kitura
import Foundation
import SwiftyJSON

extension RouterRequest {
    
    var json: JSON? {
        guard let body = self.body else {
            return nil
        }
        
        guard case let .json(json) = body else {
            return nil
        }
        
        return json
    }
    
    var urlEncoded: [String: String]? {
        guard let body = self.body else {
            return nil
        }
        
        guard case let .urlEncoded(parameters) = body else {
            return nil
        }
        return parameters
    }
}
