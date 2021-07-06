import Foundation

protocol FCMTokenUploaderProtocol {

    typealias Token = String

    func uploadToken(_ token: Token, completion: @escaping (Result<Void, Swift.Error>) -> Void)
}
