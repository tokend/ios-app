import Foundation

public protocol LoginChangerProtocol {

    func changeLogin(
        oldLogin: String,
        newLogin: String,
        password: String,
        completion: @escaping (Result<Void, Swift.Error>) -> Void
    )
}
