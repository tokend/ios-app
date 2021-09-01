import Foundation
import RxSwift
import RxCocoa

public protocol BalanceDetailsSceneBalanceProviderProtocol {
    
    var balance: BalanceDetailsScene.Model.Balance? { get }
    var loadingStatus: BalanceDetailsScene.Model.LoadingStatus { get }
    
    func observeBalance() -> Observable<BalanceDetailsScene.Model.Balance?>
    func observeLoadingStatus() -> Observable<BalanceDetailsScene.Model.LoadingStatus>
    
    func reloadBalance()
}

public extension BalanceDetailsScene {
    
    typealias BalanceProviderProtocol = BalanceDetailsSceneBalanceProviderProtocol
}
