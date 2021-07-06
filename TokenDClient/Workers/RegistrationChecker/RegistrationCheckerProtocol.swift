import Foundation

enum RegistrationCheckerIsRegisteredResult {

    case success(registered: Bool)
    case failure(Swift.Error)
}

protocol RegistrationCheckerProtocol {

    func checkIsRegistered(
        login: String,
        completion: @escaping (RegistrationCheckerIsRegisteredResult) -> Void
    )
}

