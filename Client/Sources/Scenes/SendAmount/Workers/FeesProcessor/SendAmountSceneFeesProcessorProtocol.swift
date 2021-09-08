import Foundation
import RxSwift
import RxCocoa

public protocol SendAmountSceneFeesProcessorProtocol {
    
    var fees: SendAmountScene.Model.Fees { get }
    var loadingStatus: SendAmountScene.Model.LoadingStatus { get }
    
    func observeFees() -> Observable<SendAmountScene.Model.Fees>
    func observeLoadingStatus() -> Observable<SendAmountScene.Model.LoadingStatus>
    
    func processFees(
        for amount: Decimal,
        assetId: String
    )
}

public enum SendAmountSceneFeesProcessorError: Swift.Error {
    case noData
}

extension SendAmountScene {
    public typealias FeesProcessorProtocol = SendAmountSceneFeesProcessorProtocol
}
