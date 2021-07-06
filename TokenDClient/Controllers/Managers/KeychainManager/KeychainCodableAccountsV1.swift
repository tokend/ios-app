import Foundation

class KeychainCodableAccountsV1: Codable {
    
    // MARK: - Public properties
    
    var accounts: [String] // logins
    
    // MARK: -
    
    init(accounts: [String]) {
        self.accounts = accounts
    }
}
