import Foundation
import TokenDSDK

enum VerifyEmailResendResult {
    case succeded
    case failed(Error)
}

protocol VerifyEmailResendWorkerProtocol {
    typealias Result = VerifyEmailResendResult
    
    func performResendRequest(
        completion: @escaping (_ result: Result) -> Void
    )
}
