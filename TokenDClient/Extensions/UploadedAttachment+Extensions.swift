import Foundation
import TokenDSDK

extension UploadedAttachment {
    
    enum DictionaryError: Swift.Error {
        
        case cannorSerializeAttachment
    }
    func dictionary(
    ) throws -> [String: Any] {

        let jsonEncoder: JSONEncoder = .init()
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try jsonEncoder.encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(
            with: data,
            options: []
        ) as? [String: Any]
        else {
            throw DictionaryError.cannorSerializeAttachment
        }
        
        return dictionary
    }
}
