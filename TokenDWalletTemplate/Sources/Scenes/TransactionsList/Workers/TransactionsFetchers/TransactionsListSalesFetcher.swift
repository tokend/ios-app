import Foundation
import RxSwift
import RxCocoa
import TokenDSDK

private typealias Transaction = TransactionsListScene.Model.Transaction
private typealias Amount = TransactionsListScene.Model.Amount

extension TransactionsListScene {
    class SalesFetcher: TransactionsFetcherProtocol {
        
        // MARK: - Private properties
        
        private let transactions: BehaviorRelay<Transactions> = BehaviorRelay(value: [])
        private let loadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
        private let loadingMoreStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
        private let errorStatus: PublishRelay<Swift.Error> = PublishRelay()
        
        private var pendingOffersRepoPendingOffersDisposable: Disposable?
        private var pendingOffersRepoLoadingStatusDisposable: Disposable?
        private let disposeBag: DisposeBag = DisposeBag()
        
        private let pendingOffersRepo: PendingOffersRepo
        private let balancesRepo: BalancesRepo
        private let rateProvider: RateProviderProtocol
        private let rateAsset: String = "USD"
        
        private var balanceId: String?
        private let originalAccountId: String
        private var targetBaseAsset: String?
        private var balancesIds: [String] {
            return self.balancesRepo.balancesDetailsValue.compactMap({ (balance) -> String? in
                switch balance {
                case .created(let details):
                    return details.balanceId
                case .creating:
                    return nil
                }
            })
        }
        
        // MARK: - Public properties
        
        var transactionsValue: TransactionsListSceneTransactionsFetcherProtocol.Transactions {
            return self.transactions.value
        }
        
        var loadingStatusValue: TransactionsListSceneTransactionsFetcherProtocol.LoadingStatus {
            return self.loadingStatus.value
        }
        
        var loadingMoreStatusValue: TransactionsListSceneTransactionsFetcherProtocol.LoadingStatus {
            return self.loadingMoreStatus.value
        }
        
        // MARK: -
        
        init(
            pendingOffersRepo: PendingOffersRepo,
            balancesRepo: BalancesRepo,
            rateProvider: RateProviderProtocol,
            originalAccountId: String,
            targetBaseAsset: String? = nil
            ) {
            
            self.pendingOffersRepo = pendingOffersRepo
            self.balancesRepo = balancesRepo
            self.rateProvider = rateProvider
            self.originalAccountId = originalAccountId
            self.targetBaseAsset = targetBaseAsset
            
            self.observeBalancesDetails()
            self.observeRateChanges()
            self.observeRepoErrorStatus()
            self.setBalanceId("")
            
            self.pendingOffersRepo.reloadOffers()
        }
        
        // MARK: - Public
        
        func setBalanceId(_ balanceId: String) {
            guard self.balanceId != balanceId else {
                return
            }
            self.balanceId = balanceId
            
            self.observeRepoLoadingStatus()
            self.observeRepoLoadingMoreStatus()
            self.observeRepoTransactions()
        }
        
        func observeTransactions() -> Observable<TransactionsListSceneTransactionsFetcherProtocol.Transactions> {
            return self.transactions.asObservable()
        }
        
        func observeLoadingStatus() -> Observable<TransactionsListSceneTransactionsFetcherProtocol.LoadingStatus> {
            return self.loadingStatus.asObservable()
        }
        
        func observeLoadingMoreStatus() -> Observable<TransactionsListSceneTransactionsFetcherProtocol.LoadingStatus> {
            return self.loadingMoreStatus.asObservable()
        }
        
        func observeErrorStatus() -> Observable<Swift.Error> {
            return self.errorStatus.asObservable()
        }
        
        func loadMoreTransactions() {
            return
        }
        
        func reloadTransactions() {
            self.pendingOffersRepo.reloadOffers()
        }
        
        // MARK: - Private
        
        private func reloadBalancesDetails() {
            self.balancesRepo.reloadBalancesDetails()
        }
        
        private func observeRepoLoadingStatus() {
            self.pendingOffersRepoLoadingStatusDisposable?.dispose()
            
            let disposable = self.pendingOffersRepo
                .observeLoadingStatus()
                .subscribe(onNext: { [weak self] (status) in
                    self?.loadingStatus.accept(status.status)
                })
            
            self.pendingOffersRepoLoadingStatusDisposable = disposable
            disposable.disposed(by: self.disposeBag)
        }
        
        private func observeRepoLoadingMoreStatus() { }
        
        private func observeRepoTransactions() {
            self.pendingOffersRepoPendingOffersDisposable?.dispose()
            
            let disposable = self.pendingOffersRepo
                .observeOffers()
                .subscribe(onNext: { [weak self] (_) in
                    self?.transactionsDidChange()
                })
            self.pendingOffersRepoPendingOffersDisposable = disposable
            disposable.disposed(by: self.disposeBag)
        }
        
        private func observeRepoErrorStatus() {
            self.pendingOffersRepo
                .observeErrorStatus()
                .subscribe(onNext: { [weak self] (error) in
                    self?.errorStatus.accept(error)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeBalancesDetails() {
            self.balancesRepo
                .observeBalancesDetails()
                .subscribe(onNext: { [weak self] (_) in
                    self?.transactionsDidChange()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeRateChanges() {
            self.rateProvider
                .rate
                .subscribe(onNext: { [weak self] (_) in
                    self?.transactionsDidChange()
                })
                .disposed(by: self.disposeBag)
        }
        
        // MARK: Helpers
        
        private func transactionsDidChange() {
            var transactions = self.pendingOffersRepo.offersValue
            if let targetBaseAsset = self.targetBaseAsset {
                transactions = transactions.filter({ (offer) -> Bool in
                    return offer.baseAssetCode == targetBaseAsset
                })
            }
            let parsedTransactions = self.parseOffers(transactions)
            self.transactions.accept(parsedTransactions)
        }
        
        private func parseOffers(_ offers: [PendingOffersRepo.Offer]) -> Transactions {
            let offers = offers
                .filter({ (offer) -> Bool in
                    return offer.orderBookId != 0
                })
                .map { (offer) -> Transaction in
                return self.parsePendingOffer(offer)
            }
            return offers
        }
        
        private func parsePendingOffer(
            _ offer: PendingOffersRepo.Offer
            ) -> Transaction {
            
            let amountValue: Decimal = offer.quoteAmount
            let assetValue: String = offer.quoteAssetCode
            let amount = Amount(
                value: amountValue,
                asset: assetValue
            )
            
            let counterparty: String = Localized(
                .in_asset,
                replace: [
                    .in_asset_replace_asset: offer.baseAssetCode
                ]
            )
            
            return Transaction(
                identifier: offer.offerId,
                balanceId: offer.quoteBalanceId,
                amount: amount,
                amountEffect: .sale,
                counterparty: counterparty,
                date: offer.createdAt
            )
        }
    }
}

private extension PendingOffersRepo.LoadingStatus {
    var status: TransactionsListSceneTransactionsFetcherProtocol.LoadingStatus {
        switch self {
        case .loading:
            return .loading
        case .loaded:
            return .loaded
        }
    }
}
