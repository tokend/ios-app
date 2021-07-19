import Foundation
import TokenDSDK

class TokenDAccountTypeChecker {

    // MARK: -

    init(
    ) { }
}

extension TokenDAccountTypeChecker: AccountTypeCheckerProtocol {

    func checkAccountType(
        login: String,
        completion: @escaping (AccountTypeCheckerResult) -> Void
    ) {

        completion(.success(.general))
    }
}
