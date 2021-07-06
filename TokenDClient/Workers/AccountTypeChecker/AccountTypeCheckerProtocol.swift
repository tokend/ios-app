import Foundation

enum AccountTypeCheckerResult {

    enum Error: Swift.Error {

        case notInvited
        case unsupportedAccountType
        case error(Swift.Error)
        case unknown
    }

    case failure(Error)
    case success(AccountType)
}

protocol AccountTypeCheckerProtocol {

    func checkAccountType(
        login: String,
        completion: @escaping (AccountTypeCheckerResult) -> Void
    )
}
