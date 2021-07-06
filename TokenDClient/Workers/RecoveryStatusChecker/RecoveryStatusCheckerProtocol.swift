import Foundation

public enum RecoveryStatusCheckerResult {

    case success
    case failure(Swift.Error)
}

public protocol RecoveryStatusCheckerProtocol {

    func checkRecoveryStatus(_ completion: @escaping (RecoveryStatusCheckerResult) -> Void)
}
