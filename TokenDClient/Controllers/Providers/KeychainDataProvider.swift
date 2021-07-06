import Foundation
import TokenDSDK
import DLCryptoKit

public protocol KeychainDataProviderProtocol {
    
    func getKeyData() -> ECDSA.KeyData
    func getKeysData() -> [ECDSA.KeyData]
}

public class KeychainDataProvider {
    
    // MARK: - Public properties
    
    public let account: String
    public let keychainManager: KeychainManagerProtocol
    
    // MARK: -
    
    public init?(account: String, keychainManager: KeychainManagerProtocol) {
        let keyData = keychainManager.getKeyData(account: account)
        guard keyData != nil else {
            return nil
        }
        
        self.account = account
        self.keychainManager = keychainManager
    }
}

extension KeychainDataProvider: KeychainDataProviderProtocol {
    
    public func getKeyData() -> ECDSA.KeyData {
        guard let keyData = getKeysData().first else {
            fatalError(Localized(.keychaindataprovider_should_always_provide_key))
        }
        
        return keyData
    }

    public func getKeysData() -> [ECDSA.KeyData] {
        guard let keysData = self.keychainManager.getKeyData(account: self.account) else {
            fatalError(Localized(.keychaindataprovider_should_always_provide_key))
        }

        return keysData
    }
}
