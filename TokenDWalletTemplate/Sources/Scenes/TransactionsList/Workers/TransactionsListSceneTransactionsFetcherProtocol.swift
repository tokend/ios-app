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
    
    var transactionsValue: Transactions { get }
    var loadingStatusValue: LoadingStatus { get }
    var loadingMoreStatusValue: LoadingStatus { get }
    
    func setBalanceId(_ balanceId: String)
    
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
