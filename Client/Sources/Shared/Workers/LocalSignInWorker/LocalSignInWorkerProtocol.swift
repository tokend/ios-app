import Foundation

public enum LocalSignInWorkerSignInError: Error {

    case wrongPasscode
    case noSavedAccount
}

public enum LocalSignInWorkerSignInResult {

    /// login is email or phone number, depending on what is used to log in
    case success(login: String)
    case error(error: LocalSignInWorkerSignInError)
}

public protocol LocalSignInWorkerProtocol {

    typealias SignInResult = LocalSignInWorkerSignInResult

    func performSignIn(
        login: String,
        passcode: String,
        completion: @escaping (SignInResult) -> Void
    )
}

