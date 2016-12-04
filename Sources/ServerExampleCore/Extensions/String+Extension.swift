import Foundation
import CryptoSwift

extension String {
    func toBase64() -> String {
        guard let data = self.data(using: String.Encoding.utf8) else {
            return ""
        }
        return data.base64EncodedString(options: Data.Base64EncodingOptions.init(rawValue: 0))
    }
    
    func encrypt(key: String) -> String? {
        let messageData = self.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        let keyData = key.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        let mac = HMAC(key: keyData.bytes, variant:.sha256)
        let result: [UInt8]
        do {
            result = try mac.authenticate(messageData.bytes)
        } catch {
            result = []
        }
        return String(data: Data(bytes: result), encoding: String.Encoding.utf8)?.sanitized()
    }
    
    func sanitized() -> String {
        return self
            .replacingOccurrences(of: "+", with: "-", options: String.CompareOptions.init(rawValue: 0), range: nil)
            .replacingOccurrences(of: "/", with: "_", options: String.CompareOptions.init(rawValue: 0), range: nil)
            .replacingOccurrences(of: "=", with: "", options: String.CompareOptions.init(rawValue: 0), range: nil)
    }
}
