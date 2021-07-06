import Foundation

public enum PasswordChangerError: Swift.Error {

    case wrongOldPassword
}
public protocol PasswordChangerProtocol {

    func changePassword(
        oldPassword: String,
        newPassword: String,
        completion: @escaping (ChangePasswordResult) -> Void
    )
}

public extension PasswordChangerProtocol {

    typealias ChangePasswordResult = Swift.Result<Void, Swift.Error>
}
