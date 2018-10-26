import Foundation
import TokenDSDK

protocol TFADataProviderProtocol {
    func getUserEmail() -> String?
    func getKdfParams() -> KDFParams?
}

extension UserDataManager: TFADataProviderProtocol {
    func getUserEmail() -> String? {
        return self.getMainAccount()
    }
    
    func getKdfParams() -> KDFParams? {
        guard let mainAccount = self.getMainAccount(), let walletData = self.getWalletData(account: mainAccount) else {
            return nil
        }
        
        return walletData.walletKDF.getWalletKDFParams().kdfParams
    }
}
