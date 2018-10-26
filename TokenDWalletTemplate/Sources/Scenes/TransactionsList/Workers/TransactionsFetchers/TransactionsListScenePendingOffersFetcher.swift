import Foundation
import RxSwift
import RxCocoa
import TokenDSDK

extension TransactionsListScene {
    class PendingOffersFetcher: TransactionsFetcherProtocol {
        
        // MARK: - Private properties
        
        private let transactionsBehaviorRelay: BehaviorRelay<Transactions> = BehaviorRelay(value: [])
        private let loadingStatusBehaviorRelay: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
        private let loadingMoreStatusBehaviorRelay: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
        private let errorStatus: PublishRelay<Swift.Error> = PublishRelay()
        
        private var pendingOffersRepoPendingOffersDisposable: Disposable?
        private var pendingOffersRepoLoadingStatusDisposable: Disposable?
        private let disposeBag: DisposeBag = DisposeBag()
        
        private let pendingOffersRepo: PendingOffersRepo
        private let balancesRepo: BalancesRepo
        private let rateProvider: RateProviderProtocol
        private let rateAsset: String = "USD"
        
        private var asset: String?
        private let originalAccountId: String
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
        
        var transactions: TransactionsListSceneTransactionsFetcherProtocol.Transactions {
            return self.transactionsBehaviorRelay.value
        }
        
        var loadingStatus: TransactionsListSceneTransactionsFetcherProtocol.LoadingStatus {
            return self.loadingStatusBehaviorRelay.value
        }
        
        var loadingMoreStatus: TransactionsListSceneTransactionsFetcherProtocol.LoadingStatus {
            return self.loadingMoreStatusBehaviorRelay.value
        }
        
        // MARK: -
        
        init(
            pendingOffersRepo: PendingOffersRepo,
            balancesRepo: BalancesRepo,
            rateProvider: RateProviderProtocol,
            originalAccountId: String
            ) {
            
            self.pendingOffersRepo = pendingOffersRepo
            self.balancesRepo = balancesRepo
            self.rateProvider = rateProvider
            self.originalAccountId = originalAccountId
            
            self.observeBalancesDetails()
            self.observeRateChanges()
            self.observeRepoErrorStatus()
            self.setAsset("")
        }
        
        // MARK: - Public
        
        func setAsset(_ asset: String) {
            guard self.asset != asset else {
                return
            }
            self.asset = asset
            
            self.observeRepoLoadingStatus()
            self.observeRepoLoadingMoreStatus()
            self.observeRepoTransactions()
        }
        
        func observeTransactions() -> Observable<TransactionsListSceneTransactionsFetcherProtocol.Transactions> {
            return self.transactionsBehaviorRelay.asObservable()
        }
        
        func observeLoadingStatus() -> Observable<TransactionsListSceneTransactionsFetcherProtocol.LoadingStatus> {
            return self.loadingStatusBehaviorRelay.asObservable()
        }
        
        func observeLoadingMoreStatus() -> Observable<TransactionsListSceneTransactionsFetcherProtocol.LoadingStatus> {
            return self.loadingMoreStatusBehaviorRelay.asObservable()
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
                    self?.loadingStatusBehaviorRelay.accept(status.status)
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
            let transactions = self.pendingOffersRepo.offersValue
            let parsedTransactions = self.parseOffers(transactions)
            self.transactionsBehaviorRelay.accept(parsedTransactions)
        }
        
        private func parseOffers(_ offers: [PendingOffersRepo.Offer]) -> Transactions {
            let offers = offers
                .filter({ (offer) -> Bool in
                    return offer.orderBookId == 0
                })
                .map { (offer) -> Transaction in
                    return self.parsePendingOffer(offer)
            }
            return offers
        }
        
        private func parsePendingOffer(
            _ offer: PendingOffersRepo.Offer
            ) -> Transaction {
            
            let amountValue: Decimal = offer.baseAmount
            let assetValue: String = offer.baseAssetCode
            let amount = Amount(
                value: amountValue,
                asset: assetValue
            )
            let amountType: Transaction.AmountType = offer.isBuy ? .positive : .negative
            let rate: Amount? = {
                guard let rate = self.rateProvider.rateForAmount(
                    amountValue,
                    ofAsset: assetValue,
                    destinationAsset: self.rateAsset
                    ) else {
                        return nil
                }
                return Amount(
                    value: rate,
                    asset: self.rateAsset
                )
            }()
            let counterparty: String = "For \(offer.quoteAssetCode)"
            
            return Transaction(
                identifier: offer.offerId,
                type: .pendingOffer(buy: offer.isBuy),
                amount: amount,
                amountType: amountType,
                counterparty: counterparty,
                rate: rate,
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

private typealias Transaction = TransactionsListScene.Model.Transaction
private typealias Amount = TransactionsListScene.Model.Amount
