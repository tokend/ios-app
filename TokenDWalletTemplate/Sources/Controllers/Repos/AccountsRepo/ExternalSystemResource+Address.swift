import Foundation
import TokenDSDK

extension Horizon.ExternalSystemIDResource {
    
    public var addressWithPayload: AddressWithPayload? {
        guard let data = self.data else { return nil }
        if data.data.payload == nil {
            return nil
        }
        
        return AddressWithPayload(type: data.type, data: AddressWithPayload.Data(address: data.data.address, payload: data.data.payload ?? ""))
    }
    
    public var address: Address? {
        guard let data = self.data else { return nil }
        if data.data.payload != nil {
            return nil
        }
        
        return Address(type: data.type, data: Address.Data(address: data.data.address))
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
