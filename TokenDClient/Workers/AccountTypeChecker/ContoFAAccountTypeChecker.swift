import Foundation
import TokenDSDK

class ContoFAAccountTypeChecker {

    // MARK: -

    init(
    ) { }
}

extension ContoFAAccountTypeChecker: AccountTypeCheckerProtocol {

    func checkAccountType(
        login: String,
        completion: @escaping (AccountTypeCheckerResult) -> Void
    ) {

        completion(.success(.general))
    }
}


