import Foundation
import RxSwift
import RxCocoa

extension TransactionsListScene {
    class PreviewTransactionsFetcher {
        
        private let transactionsFetcher: TransactionsFetcherProtocol
        private let previewMaxLength: Int
        
        init(
            transactionsFetcher: TransactionsFetcherProtocol,
            previewMaxLength: Int
            ) {
            
            self.transactionsFetcher = transactionsFetcher
            self.previewMaxLength = previewMaxLength
        }
        
        private func convertTransactionsToPreview(
            _ transactions: Transactions
            ) -> Transactions {
            
            return Array(transactions.prefix(self.previewMaxLength))
        }
    }
}

extension TransactionsListScene.PreviewTransactionsFetcher: TransactionsListScene.TransactionsFetcherProtocol {
    
    var transactions: Transactions {
        return self.convertTransactionsToPreview(self.transactionsFetcher.transactions)
    }
    
    var loadingStatus: LoadingStatus {
        return self.transactionsFetcher.loadingStatus
    }
    var loadingMoreStatus: LoadingStatus {
        return .loaded
    }
    
    func setAsset(_ asset: String) {
        self.transactionsFetcher.setAsset(asset)
    }
    
    func observeTransactions() -> Observable<Transactions> {
        return self.transactionsFetcher
            .observeTransactions()
            .map({ (transactions) -> Transactions in
                return self.convertTransactionsToPreview(transactions)
            })
    }
    
    func reloadTransactions() {
        self.transactionsFetcher.reloadTransactions()
    }
    
    func loadMoreTransactions() { }
    
    func observeLoadingStatus() -> Observable<LoadingStatus> {
       return self.transactionsFetcher.observeLoadingStatus()
    }
    
    func observeLoadingMoreStatus() -> Observable<LoadingStatus> {
        return BehaviorRelay(value: self.loadingMoreStatus).asObservable()
    }
    
    func observeErrorStatus() -> Observable<Error> {
        return self.transactionsFetcher.observeErrorStatus()
    }
    
}
