import Foundation
import TokenDSDK

public enum AccountKYCCheckerResult {

    case error(Swift.Error)
    case success(ReviewableRequestState)
    case noKyc
}

public protocol AccountKYCCheckerProtocol {

    func checkKYC(_ completion: @escaping (AccountKYCCheckerResult) -> Void)
}
