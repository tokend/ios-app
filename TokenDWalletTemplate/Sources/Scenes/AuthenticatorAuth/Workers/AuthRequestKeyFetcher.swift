import Foundation
import DLCryptoKit
import TokenDWallet

protocol AuthRequestKeyFectherProtocol {
    func getKey() -> ECDSA.KeyData?
    func getPublicKey() -> String?
}

extension AuthenticatorAuth {
    
    class AuthRequestKeyFecther {
        
        // MARK: - Private properties
        
        private var key: ECDSA.KeyData?
    }
}

extension AuthenticatorAuth.AuthRequestKeyFecther: AuthRequestKeyFectherProtocol {
    
    func getKey() -> ECDSA.KeyData? {
        if let key = self.key {
            return key
        } else {
            self.key = try? ECDSA.KeyData()
            return self.getKey()
        }
    }
    
    func getPublicKey() -> String? {
        if let key = self.key {
            return Base32Check.encode(version: .accountIdEd25519, data: key.getPublicKeyData())
        } else {
            self.key = try? ECDSA.KeyData()
            return self.getPublicKey()
        }
    }
}
