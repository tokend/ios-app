import Foundation
import RxSwift
import RxCocoa

public protocol SendAmountSceneSelectedBalanceProviderProtocol {
    
    var selectedBalance: SendAmountScene.Model.Balance { get }
    
    func observeBalance() -> Observable<SendAmountScene.Model.Balance>
}

extension SendAmountScene {
    public typealias SelectedBalanceProviderProtocol = SendAmountSceneSelectedBalanceProviderProtocol
}
