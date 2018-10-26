import Foundation

enum BalanceCreatorProtocolCreateBalanceResult {
    case succeeded
    case failed
}

protocol BalanceCreatorProtocol {
    typealias Asset = String
    typealias CreateBalanceResult = BalanceCreatorProtocolCreateBalanceResult
    
    func createBalanceForAsset(
        _ asset: Asset,
        completion: @escaping (CreateBalanceResult) -> Void
    )
}
