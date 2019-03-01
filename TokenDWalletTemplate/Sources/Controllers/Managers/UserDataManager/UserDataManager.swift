import Foundation
import TokenDSDK

protocol UserDataManagerProtocol {
    
    func hasWalletDataForMainAccount() -> Bool
    func getMainAccount() -> String?
    func saveWalletData(_ walletData: WalletDataSerializable, account: String) -> Bool
    func getWalletData(account: String) -> WalletDataSerializable?
    func removeWalletData(account: String) -> Bool
    func isSignedViaAuthenticator() -> Bool
    
    func clearAllData()
}

class UserDataManager {
    
    // MARK: - Private properties
    
    let keychainManager: KeychainManagerProtocol
    
    // MARK: -
    
    init(keychainManager: KeychainManagerProtocol) {
        self.keychainManager = keychainManager
    }
}

extension UserDataManager: UserDataManagerProtocol {
    
    // User data
    
    func hasWalletDataForMainAccount() -> Bool {
        guard let mainAccount = self.getMainAccount() else {
            return false
        }
        
        return self.keychainManager.hasOpaqueData(account: mainAccount, keyPostfix: .walletData)
    }
    
    func getMainAccount() -> String? {
        return self.keychainManager.getMainAccount()
    }
    
    func saveWalletData(_ walletData: WalletDataSerializable, account: String) -> Bool {
        guard let encodedData = walletData.encodedSerializableData() else {
            return false
        }
        
        return self.keychainManager.saveOpaqueData(
            encodedData,
            account: account,
            keyPostfix: .walletData
        )
    }
    
    func getWalletData(account: String) -> WalletDataSerializable? {
        guard let encodedDate = self.keychainManager.getOpaqueData(
            account: account,
            keyPostfix: .walletData
            ) else {
                return nil
        }
        
        return WalletDataSerializable.fromSerializedData(serializedData: encodedDate)
    }
    
    func removeWalletData(account: String) -> Bool {
        return self.keychainManager.removeOpaqueData(account: account, keyPostfix: .walletData)
    }
    
    func clearAllData() {
        guard let mainAccount = self.getMainAccount() else {
            return
        }
        
        _ = self.removeWalletData(account: mainAccount)
    }
    
    func isSignedViaAuthenticator() -> Bool {
        guard let mainAccount = self.getMainAccount(),
            let serializedData = self.keychainManager.getOpaqueData(account: mainAccount, keyPostfix: .walletData),
            let walletData = WalletDataSerializable.fromSerializedData(serializedData: serializedData) else {
                return false
        }
        
        return walletData.signedViaAuthenticator
    }
}
