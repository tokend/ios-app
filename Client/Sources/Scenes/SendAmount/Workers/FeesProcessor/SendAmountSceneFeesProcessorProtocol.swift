import Foundation
import RxSwift
import RxCocoa

public protocol SendAmountSceneFeesProcessorProtocol {
    
    var feesList: [Decimal: SendAmountScene.Model.Fees] { get }
    var loadingStatus: SendAmountScene.Model.LoadingStatus { get }
    
    func observeFees() -> Observable<[Decimal: SendAmountScene.Model.Fees]>
    func observeLoadingStatus() -> Observable<SendAmountScene.Model.LoadingStatus>
    
    func processFees(
        for amount: Decimal,
        assetId: String
    )
}

extension SendAmountScene {
    public typealias FeesProcessorProtocol = SendAmountSceneFeesProcessorProtocol
}
