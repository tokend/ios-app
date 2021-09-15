import Foundation
import RxSwift
import RxCocoa

public protocol SendAmountSceneInfoProviderProtocol {
    
    var recipientAddress: String { get }
    var selectedBalance: SendAmountScene.Model.Balance { get }
    
    func observeBalance() -> Observable<SendAmountScene.Model.Balance>
}

extension SendAmountScene {
    public typealias InfoProviderProtocol = SendAmountSceneInfoProviderProtocol
}
