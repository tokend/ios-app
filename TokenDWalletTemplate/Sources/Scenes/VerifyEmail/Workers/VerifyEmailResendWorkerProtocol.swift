import Foundation
import TokenDSDK

enum VerifyEmailResendResult {
    case succeded
    case failed(ApiErrors)
}

protocol VerifyEmailResendWorkerProtocol {
    typealias Result = VerifyEmailResendResult
    
    func performResendRequest(
        completion: @escaping (_ result: Result) -> Void
    )
}
