import Foundation

enum LoginWorkerResult {

    case success(login: String)
    case failure(Swift.Error)
}

protocol LoginWorkerProtocol {

    func loginAction(
        login: String,
        password: String,
        completion: @escaping (LoginWorkerResult) -> Void
    )
}
