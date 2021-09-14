import Foundation
import TokenDSDK
import RxSwift
import RxCocoa

public protocol FeesProcessorProtocol {
    
    var fees: FeesProcessorFeesModel? { get }
    var loadingStatus: FeesProcessorLoadingStatus { get }
    
    func observeFees() -> Observable<FeesProcessorFeesModel?>
    func observeLoadingStatus() -> Observable<FeesProcessorLoadingStatus>
    
    func processFees(
        for recipientAccountId: String,
        amount: Decimal,
        assetId: String
    )
}

public struct FeesProcessorFeesModel {
    let senderFee: Horizon.CalculatedFeeResource
    let recipientFee: Horizon.CalculatedFeeResource
}

public enum FeesProcessorLoadingStatus {
    case loaded
    case loading
}

public enum FeesProcessorError: Swift.Error {
    case noData
}
