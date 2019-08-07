import Foundation

enum BalanceBinderBindBalanceResult {
    case succeeded
    case failed
}

protocol BalanceBinderProtocol {
    
    func bindBalance(
        _ asset: String,
        toAccount externalType: Int32,
        completion: @escaping (BalanceBinderBindBalanceResult) -> Void
    )
}
