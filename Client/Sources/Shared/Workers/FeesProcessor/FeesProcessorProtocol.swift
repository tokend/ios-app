import Foundation
import TokenDSDK
import RxSwift
import RxCocoa

public protocol FeesProcessorProtocol {
    
    var fees: FeesProcessorFeesModel? { get }
    
    func processFees(
        for recipientAccountId: String,
        amount: Decimal,
        assetId: String,
        completion: @escaping (Result<FeesProcessorFeesModel, Swift.Error>) -> Void
    )
}

public struct FeesProcessorFeesModel {
    let senderFee: Horizon.CalculatedFeeResource
    let recipientFee: Horizon.CalculatedFeeResource
}

public enum FeesProcessorError: Swift.Error {
    case noData
    case failedToFetchFees
}
