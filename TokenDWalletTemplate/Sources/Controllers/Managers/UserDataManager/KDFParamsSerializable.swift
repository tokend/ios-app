import Foundation
import TokenDSDK

struct KDFParamsSerializable: Codable {
    
    public static let serializationVersion: UInt = 2
    
    let algorithm: String
    let bits: Int64
    let id: String
    let n: UInt64
    let p: UInt32
    let r: UInt32
    let type: String
    let serializationVersion: UInt = KDFParamsSerializable.serializationVersion
    
    static func fromKDFParams(_ kdfParams: KDFParams) -> KDFParamsSerializable {
        return KDFParamsSerializable(
            algorithm: kdfParams.algorithm,
            bits: kdfParams.bits,
            id: kdfParams.id,
            n: kdfParams.n,
            p: kdfParams.p,
            r: kdfParams.r,
            type: kdfParams.type
        )
    }
    
    func getKDFParams() -> KDFParams {
        return KDFParams(
            algorithm: self.algorithm,
            bits: self.bits,
            id: self.id,
            n: self.n,
            p: self.p,
            r: self.r,
            type: self.type
        )
    }
    
    static func fromSerializedData(serializedData: Data) -> KDFParamsSerializable? {
        if let serializable = try? JSONDecoder().decode(KDFParamsSerializable.self, from: serializedData) {
            return serializable
        }
        
        return nil
    }
    
    func encodedSerializableData() -> Data? {
        let data = try? JSONEncoder().encode(self)
        
        return data
    }
}
