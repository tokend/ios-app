import Foundation
import TokenDSDK
import DLCryptoKit

protocol KeychainDataProviderProtocol {
    func getKeyData() -> ECDSA.KeyData
}

class KeychainDataProvider {
    
    // MARK: - Public properties
    
    let account: String
    let keychainManager: KeychainManagerProtocol
    
    // MARK: -
    
    init?(account: String, keychainManager: KeychainManagerProtocol) {
        let keyData = keychainManager.getKeyData(account: account)
        guard keyData != nil else {
            return nil
        }
        
        self.account = account
        self.keychainManager = keychainManager
    }
}

extension KeychainDataProvider: KeychainDataProviderProtocol {
    func getKeyData() -> ECDSA.KeyData {
        guard let keyData = self.keychainManager.getKeyData(account: self.account) else {
            fatalError(Localized(.keychaindataprovider_should_always_provide_key))
        }
        
        return keyData
    }
}
