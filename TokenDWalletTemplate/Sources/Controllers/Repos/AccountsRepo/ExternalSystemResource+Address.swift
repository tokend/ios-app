import Foundation
import TokenDSDK

extension ExternalSystemIdResource {
    
    public var addressWithPayload: AddressWithPayload? {
        guard let jsonData = self.data.data(using: .utf8) else { return nil }
        
        return try? JSONDecoder().decode(AddressWithPayload.self, from: jsonData)
    }
    
    public var address: Address? {
        guard let jsonData = self.data.data(using: .utf8) else { return nil }
        
        return try? JSONDecoder().decode(Address.self, from: jsonData)
    }
    
    public struct AddressWithPayload: Decodable {
        public let type: String
        public let data: Data
        
        public struct Data: Decodable {
            let address: String
            let payload: String
        }
    }
    
    public struct Address: Decodable {
        public let type: String
        public let data: Data
        
        public struct Data: Decodable {
            let address: String
        }
    }
}
