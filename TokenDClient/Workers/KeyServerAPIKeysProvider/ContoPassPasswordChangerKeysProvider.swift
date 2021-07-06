import Foundation
import TokenDSDK
import DLCryptoKit

class ContoPassPasswordChangerKeysProvider {
    
    private let mainKeyPair: ECDSA.KeyData
    private let keychainDataProvider: KeychainDataProviderProtocol
    
    init(
        keychainDataProvider: KeychainDataProviderProtocol
    ) throws {
        
        mainKeyPair = try .init()
        
        self.keychainDataProvider = keychainDataProvider
    }
}

extension ContoPassPasswordChangerKeysProvider: KeyServerAPIKeysProviderProtocol {
    
    var requestSigningKey: ECDSA.KeyData {
        keychainDataProvider.getKeyData()
    }
    
    var mainKey: ECDSA.KeyData {
        mainKeyPair
    }
    
    var keys: [ECDSA.KeyData] {
        [mainKeyPair]
    }
    
    func getSigners(
        completion: @escaping (Result<[Signer], Error>) -> Void
    ) {
        
    }
}
