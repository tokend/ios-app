import Foundation

public protocol ForgotPasswordWorkerProtocol {

    func changePassword(
        login: String,
        newPassword: String,
        completion: @escaping (Result<Void, Swift.Error>) -> Void
    )
}
