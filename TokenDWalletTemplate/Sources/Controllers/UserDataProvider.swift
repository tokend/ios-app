import Foundation
import TokenDSDK

protocol UserDataProviderProtocol {
    
    var userEmail: String { get }
    var accountId: String { get }
    var walletData: WalletData { get }
    var walletId: String { get }
}

struct UserDataProvider {
    let userEmail: String
    let accountId: String
    let walletData: WalletData
    let walletId: String
}

extension UserDataProvider: UserDataProviderProtocol { }
