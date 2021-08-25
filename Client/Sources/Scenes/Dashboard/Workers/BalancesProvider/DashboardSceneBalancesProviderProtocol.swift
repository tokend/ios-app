import Foundation
import RxSwift
import RxCocoa

public protocol DashboardSceneBalancesProviderProtocol {
    
    var balances: [DashboardScene.Model.Balance] { get }
    var loadingStatus: DashboardScene.Model.LoadingStatus { get }
    
    func observeBalances() -> Observable<[DashboardScene.Model.Balance]>
    func observeLoadingStatus() -> Observable<DashboardScene.Model.LoadingStatus>
    
    func initiateReload()
}

extension DashboardScene {
    public typealias BalancesProviderProtocol = DashboardSceneBalancesProviderProtocol
}
