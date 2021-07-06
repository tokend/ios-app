import Foundation
import TokenDSDK
import DLCryptoKit

class ContoFAForgotPasswordKeysProvider {

    private let mainKeyPair: ECDSA.KeyData
    private let paymentsKeyPair: ECDSA.KeyData
    
    init(
    ) throws {
        
        mainKeyPair = try .init()
        paymentsKeyPair = try .init()
    }
}

extension ContoFAForgotPasswordKeysProvider: KeyServerAPIKeysProviderProtocol {
    
    var requestSigningKey: ECDSA.KeyData {
        mainKeyPair
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
        // Signers are not neeeded for this opeeration
    }
}
