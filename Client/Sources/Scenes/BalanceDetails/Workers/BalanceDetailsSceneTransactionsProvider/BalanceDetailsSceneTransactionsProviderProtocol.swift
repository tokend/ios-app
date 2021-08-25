import Foundation
import RxSwift
import RxCocoa

public protocol BalanceDetailsSceneTransactionsProviderProtocol {
    
    var transactions: [BalanceDetailsScene.Model.Transaction] { get }
    var loadingStatus: BalanceDetailsScene.Model.LoadingStatus { get }
    
    func observeTransactions() -> Observable<[BalanceDetailsScene.Model.Transaction]>
    func observeLoadingStatus() -> Observable<BalanceDetailsScene.Model.LoadingStatus>
    
    func reloadTransactions()
}

public extension BalanceDetailsScene {
    
    typealias TransactionsProviderProtocol = BalanceDetailsSceneTransactionsProviderProtocol
}
