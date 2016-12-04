import Foundation
import KituraRequest

public struct FormURLEncoding: Encoding {

    public static let `default` = FormURLEncoding()

    public func encode(_ request: inout URLRequest, parameters: Request.Parameters?) throws {
        guard let parameters = parameters, !parameters.isEmpty else { return }

        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let query = parameters.map({ "\($0.key)=\($0.value)" }).joined(separator: "&")

        request.httpBody = query.data(using: String.Encoding.utf8)
    }
}
