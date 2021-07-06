import Foundation
import TokenDSDK

enum AccountType: CaseIterable {
    
    case blocked
    case corporate
    case general
    case unverified
    
    var userKey: String {
        switch self {
        case .blocked: return KeyValueEntries.accountRoleBlocked
        case .corporate: return KeyValueEntries.accountRoleCorporate
        case .general: return KeyValueEntries.accountRoleGeneral
        case .unverified: return KeyValueEntries.accountRoleUnverified
        }
    }
}

enum AccountTypeFetcherError: Swift.Error {
    
    case unsupportedAccountType
}

protocol AccountTypeFetcherProtocol {
    
    func fetchAccountType(
        login: String,
        completion: @escaping (Result<AccountType, Swift.Error>) -> Void
    )
}
