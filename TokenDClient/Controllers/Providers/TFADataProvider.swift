import Foundation
import TokenDSDK

protocol TFADataProviderProtocol {
    func getUserLogin() -> String?
    func getKdfParams() -> KDFParams?
}

extension UserDataManager: TFADataProviderProtocol {
    func getUserLogin() -> String? {
        return self.getMainAccount()
    }
    
    func getKdfParams() -> KDFParams? {
        guard let mainAccount = self.getMainAccount(), let walletData = self.getWalletData(account: mainAccount) else {
            return nil
        }
        
        return walletData.walletKDF.getWalletKDFParams().kdfParams
    }
}
