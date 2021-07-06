import Foundation
import TokenDSDK
import DLCryptoKit

class ContoFAPasswordChangerKeysProvider {
    
    private let mainKeyPair: ECDSA.KeyData
    private let paymentsKeyPair: ECDSA.KeyData
    private let keychainDataProvider: KeychainDataProviderProtocol
    
    init(
        keychainDataProvider: KeychainDataProviderProtocol
    ) throws {
        
        mainKeyPair = try .init()
        paymentsKeyPair = try .init()
        
        self.keychainDataProvider = keychainDataProvider
    }
}

extension ContoFAPasswordChangerKeysProvider: KeyServerAPIKeysProviderProtocol {
    
    var requestSigningKey: ECDSA.KeyData {
        keychainDataProvider.getKeyData()
    }
    
    var mainKey: ECDSA.KeyData {
        mainKeyPair
    }
    
    var keys: [ECDSA.KeyData] {
        [mainKeyPair, paymentsKeyPair]
    }
    
    func getSigners(
        completion: @escaping (Result<[Signer], Error>) -> Void
    ) {
        
    }
}
