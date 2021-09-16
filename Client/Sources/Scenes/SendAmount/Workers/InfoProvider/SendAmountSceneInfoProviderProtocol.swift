import Foundation
import RxSwift
import RxCocoa

public protocol SendAmountSceneInfoProviderProtocol {
    
    var recipientAddress: String { get }
    var selectedBalance: SendAmountScene.Model.Balance { get }
    var fees: SendAmountScene.Model.Fees { get }
    var feesLoadingStatus: SendAmountScene.Model.LoadingStatus { get }
    
    func observeBalance() -> Observable<SendAmountScene.Model.Balance>
    func observeFees() -> Observable<SendAmountScene.Model.Fees>
    func observeFeesLoadingStatus() -> Observable<SendAmountScene.Model.LoadingStatus>
    
    func calculateFees(
        for amount: Decimal,
        assetId: String
    )
}

extension SendAmountScene {
    public typealias InfoProviderProtocol = SendAmountSceneInfoProviderProtocol
}
