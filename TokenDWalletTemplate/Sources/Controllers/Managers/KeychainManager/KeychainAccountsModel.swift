import Foundation

class KeychainAccountsModel: Codable {
    
    // MARK: - Public properties
    
    let version: UInt
    var encodedAccounts: Data // encoded emails
    
    // MARK: -
    
    init(version: UInt, encodedAccounts: Data) {
        self.version = version
        self.encodedAccounts = encodedAccounts
    }
    
    // MARK: - Public
    
    func getAccounts() -> [String]? {
        return KeychainAccountsModel.decodeAccounts(self.encodedAccounts, version: self.version)
    }
    
    // MARK: - Coding
    
    static func decodeAccounts(_ encodedAccounts: Data, version: UInt) -> [String]? {
        switch version {
            
        case 1:
            guard let accountsModel = try? JSONDecoder().decode(
                KeychainCodableAccountsV1.self,
                from: encodedAccounts
                ) else {
                    return nil
            }
            return accountsModel.accounts
            
        default:
            let function = #function
            print(Localized(
                .unsupported_version,
                replace: [
                    .unsupported_version_replace_function: function
                ]
            )
)
            return nil
        }
    }
    
    static func encodeAccounts(_ accounts: [String]) -> (version: UInt, encodedAccounts: Data)? {
        let accountsModel = KeychainCodableAccountsV1(accounts: accounts)
        guard let encodedAccounts = try? JSONEncoder().encode(accountsModel) else {
            return nil
        }
        return (1, encodedAccounts)
    }
}
