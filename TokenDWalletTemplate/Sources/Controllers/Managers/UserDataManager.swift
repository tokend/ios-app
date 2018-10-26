import Foundation
import TokenDSDK

protocol UserDataManagerProtocol {
    
    /// User email
    func saveUserEmail(_ email: String)
    func getUserEmail() -> String?
    
    /// Wallet data
    func saveWalletData(_ walletData: WalletDataModel)
    func getWalletData() -> WalletDataModel?
    
    /// Registration data
    func saveWalletId(_ walletId: String)
    func getWalletId() -> String?
}

class UserDataManager {
    
    // MARK: - Private properties
    
    private var userEmail: String?
    private var walletData: WalletDataModel?
}

extension UserDataManager: UserDataManagerProtocol {
    func saveUserEmail(_ email: String) {
        self.userEmail = email
    }
    
    func getUserEmail() -> String? {
        if let email = self.getWalletData()?.email {
            return email
        }
        return self.userEmail
    }
    
    func saveWalletData(_ walletData: WalletDataModel) {
        self.walletData = walletData
    }
    
    func getWalletData() -> WalletDataModel? {
        return self.walletData
    }
    
    private static let registrationWalletIdKey = "registrationWalletIdKey"
    func saveWalletId(_ walletId: String) {
        UserDefaults.standard.set(walletId, forKey: UserDataManager.registrationWalletIdKey)
    }
    
    func getWalletId() -> String? {
        if let walletId = self.getWalletData()?.walletId {
            return walletId
        }
        return UserDefaults.standard.string(forKey: UserDataManager.registrationWalletIdKey)
    }
}
