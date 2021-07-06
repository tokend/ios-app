import Foundation
import TokenDSDK
import DLCryptoKit

class ContoPassForgotPasswordKeysProvider {
    
    private let mainKeyPair: ECDSA.KeyData
    
    init(
    ) throws {
        
        mainKeyPair = try .init()
    }
}

extension ContoPassForgotPasswordKeysProvider: KeyServerAPIKeysProviderProtocol {
    
    var requestSigningKey: ECDSA.KeyData {
        mainKeyPair
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
        // Signers are not neeeded for this opeeration
    }
}
