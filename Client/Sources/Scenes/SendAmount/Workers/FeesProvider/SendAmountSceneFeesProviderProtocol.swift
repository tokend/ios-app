import Foundation
import RxSwift
import RxCocoa

public protocol SendAmountSceneFeesProviderProtocol {
    
    var fees: SendAmountScene.Model.Fees { get }
    var loadingStatus: SendAmountScene.Model.LoadingStatus { get }
    
    func observeFees() -> Observable<SendAmountScene.Model.Fees>
    func observeLoadingStatus() -> Observable<SendAmountScene.Model.LoadingStatus>
    
    func processFees(
        for amount: Decimal,
        assetId: String
    )
}

extension SendAmountScene {
    public typealias FeesProviderProtocol = SendAmountSceneFeesProviderProtocol
}
