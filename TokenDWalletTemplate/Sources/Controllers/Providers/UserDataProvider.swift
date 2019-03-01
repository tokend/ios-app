import Foundation
import TokenDSDK
import TokenDWallet

protocol UserDataProviderProtocol {
    
    var account: String { get }
    var walletData: WalletDataSerializable { get }
    var accountId: TokenDWallet.AccountID { get }
    var userEmail: String { get }
    var walletId: String { get }
    
    var userDataManager: UserDataManagerProtocol { get } 
}

class UserDataProvider {
    
    let account: String
    let accountId: AccountID
    let userDataManager: UserDataManagerProtocol
    
    init?(account: String, accountId: AccountID, userDataManager: UserDataManagerProtocol) {
        let walletData = userDataManager.getWalletData(account: account)
        guard walletData != nil else {
            return nil
        }
        
        self.account = account
        self.accountId = accountId
        self.userDataManager = userDataManager
    }
}

extension UserDataProvider: UserDataProviderProtocol {
    
    var walletData: WalletDataSerializable {
        guard let walletData = self.userDataManager.getWalletData(account: self.account) else {
            fatalError(Localized(.userdataprovider_should_always_provide_walletdata))
        }
        
        return walletData
    }
    
    var userEmail: String {
        return self.walletData.email
    }
    
    var walletId: String {
        return self.walletData.walletId
    }
}
