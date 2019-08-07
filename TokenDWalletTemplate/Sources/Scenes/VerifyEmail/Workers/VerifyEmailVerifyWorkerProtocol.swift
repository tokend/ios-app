import Foundation
import TokenDSDK

enum VerifyEmailVerifyResult {
    case succeded
    case failed(Swift.Error)
}

protocol VerifyEmailVerifyWorkerProtocol {
    typealias Result = VerifyEmailVerifyResult
    
    func performVerifyRequest(
        token: String,
        completion: @escaping (_ result: Result) -> Void
    )
    
    func verifyEmailTokenFrom(url: URL) -> String?
}
