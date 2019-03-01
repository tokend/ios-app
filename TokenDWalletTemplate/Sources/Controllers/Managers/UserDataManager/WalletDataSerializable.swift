import Foundation
import TokenDSDK

struct WalletDataSerializable: Codable {
    
    public static let serializationVersion: UInt = 2
    
    let email: String
    let accountId: String
    let walletId: String
    let type: String
    let keychainData: Data
    let network: AccountNetworkModel
    let walletKDF: WalletKDFSerializable
    let verified: Bool
    let signedViaAuthenticator: Bool
    let serializationVersion: UInt = WalletDataSerializable.serializationVersion
    
    struct WalletKDFSerializable: Codable {
        
        let kdfParams: KDFParamsSerializable
        let salt: Data
        
        static func fromWalletKDFParams(_ walletKDF: WalletKDFParams) -> WalletKDFSerializable {
            return WalletKDFSerializable(
                kdfParams: KDFParamsSerializable.fromKDFParams(walletKDF.kdfParams),
                salt: walletKDF.salt
            )
        }
        
        func getWalletKDFParams() -> WalletKDFParams {
            return WalletKDFParams(
                kdfParams: self.kdfParams.getKDFParams(),
                salt: self.salt
            )
        }
    }
    
    public struct AccountNetworkModel: Codable {
        
        public let masterAccountId: String
        public let name: String
        public let passphrase: String
        public let rootUrl: String
        public let storageUrl: String
        
        init(
            masterAccountId: String,
            name: String,
            passphrase: String,
            rootUrl: String,
            storageUrl: String
            ) {
            
            self.masterAccountId = masterAccountId
            self.name = name
            self.passphrase = passphrase
            self.rootUrl = rootUrl
            self.storageUrl = storageUrl
        }
    }
    
    static func fromWalletData(
        _ walletData: WalletDataModel,
        signedViaAuthenticator: Bool,
        network: AccountNetworkModel
        ) -> WalletDataSerializable? {
        
        guard let keychainData = walletData.keychainData.dataFromBase64 else {
            return nil
        }
        
        return WalletDataSerializable(
            email: walletData.email,
            accountId: walletData.accountId,
            walletId: walletData.walletId,
            type: walletData.type,
            keychainData: keychainData,
            network: network,
            walletKDF: WalletKDFSerializable.fromWalletKDFParams(walletData.walletKDF),
            verified: walletData.verified,
            signedViaAuthenticator: signedViaAuthenticator
        )
    }
    
    static func fromSerializedData(serializedData: Data) -> WalletDataSerializable? {
        if let serializable = try? JSONDecoder().decode(WalletDataSerializable.self, from: serializedData) {
            return serializable
        }
        
        guard
            let dict = (try? JSONSerialization.jsonObject(with: serializedData, options: [])) as? [String: Any]
            else {
                return nil
        }
        
        guard let serializationVersion = dict["serializationVersion"] as? UInt else {
            return nil
        }
        
        switch serializationVersion {
            
        case WalletDataSerializable1.serializationVersion:
            if let serializable = try? JSONDecoder().decode(
                WalletDataSerializable1.self,
                from: serializedData
                ),
                let keychainData = serializable.keychainData.dataFromBase64 {
                
                let walletData = WalletDataSerializable(
                    email: serializable.email,
                    accountId: serializable.accountId,
                    walletId: serializable.walletId,
                    type: serializable.type,
                    keychainData: keychainData,
                    network: serializable.network,
                    walletKDF: serializable.walletKDF,
                    verified: serializable.verified,
                    signedViaAuthenticator: serializable.signedViaAuthenticator
                )
                
                return walletData
            }
            
            return nil
            
        default:
            return nil
        }
    }
    
    func encodedSerializableData() -> Data? {
        let data = try? JSONEncoder().encode(self)
        
        return data
    }
}

private struct WalletDataSerializable1: Codable {
    
    public static let serializationVersion: UInt = 1
    
    let email: String
    let accountId: String
    let walletId: String
    let type: String
    let keychainData: String
    let network: WalletDataSerializable.AccountNetworkModel
    let walletKDF: WalletDataSerializable.WalletKDFSerializable
    let verified: Bool
    let signedViaAuthenticator: Bool
    let serializationVersion: UInt = WalletDataSerializable1.serializationVersion
}
