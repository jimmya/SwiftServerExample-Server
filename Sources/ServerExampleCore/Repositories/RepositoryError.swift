import Foundation
import KituraNet

enum RepositoryError: Swift.Error {
    case BadRequest(String?)
    case NotFound(String?)
    case InternalServerError(String?)
}

extension RepositoryError {
    
    var statusCode: HTTPStatusCode {
        switch self {
        case .BadRequest(_):
            return .badRequest
        case .NotFound(_):
            return .notFound
        case .InternalServerError(_):
            return .internalServerError
        }
    }
    
    var message: String {
        var message: String?
        switch self {
        case .BadRequest(let string):
            message = string
        case .NotFound(let string):
            message = string
        case .InternalServerError(let string):
            message = string
        }
        return message ?? "Unknown error occured"
    }
}
