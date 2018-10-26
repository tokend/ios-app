import Foundation
import RxSwift
import RxCocoa

enum TransactionsListSceneTransactionsLoadingStatus {
    case loading
    case loaded
}

protocol TransactionsListSceneTransactionsFetcherProtocol {
    typealias Transaction = TransactionsListScene.Model.Transaction
    typealias Transactions = [Transaction]
    typealias LoadingStatus = TransactionsListSceneTransactionsLoadingStatus
    
    var transactions: Transactions { get }
    var loadingStatus: LoadingStatus { get }
    var loadingMoreStatus: LoadingStatus { get }
    
    func setAsset(_ asset: String)
    
    func observeTransactions() -> Observable<Transactions>
    func reloadTransactions()
    func loadMoreTransactions()
    func observeLoadingStatus() -> Observable<LoadingStatus>
    func observeLoadingMoreStatus() -> Observable<LoadingStatus>
    func observeErrorStatus() -> Observable<Swift.Error>
}

extension TransactionsListScene {
    typealias TransactionsFetcherProtocol = TransactionsListSceneTransactionsFetcherProtocol
}
