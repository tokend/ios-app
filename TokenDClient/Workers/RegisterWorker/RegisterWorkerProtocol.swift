import Foundation

enum RegisterWorkerResult {

    case success(login: String)
    case failure(Swift.Error)
}

protocol RegisterWorkerProtocol {

    func registerAction(
        login: String,
        password: String,
        completion: @escaping (RegisterWorkerResult) -> Void
    )
}
