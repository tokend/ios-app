import Foundation
import RxCocoa
import RxSwift
import TokenDSDK

extension TransactionsListScene {
    class PaymentsFetcher: TransactionsFetcherProtocol {
        
        // MARK: - Private properties
        
        private var transactionsHistoryRepo: TransactionsHistoryRepo?
        private let errorsStatus: PublishRelay<Swift.Error> = PublishRelay()
        
        private var trHistoryRepoTransactionsDisposable: Disposable?
        private var trHistoryRepoLoadingStatusDisposable: Disposable?
        private var trHistoryRepoLoadingMoreStatusDisposable: Disposable?
        private var trHistoryRepoErrorsStatusDisposable: Disposable?
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        private let reposController: ReposController
        private let rateProvider: RateProviderProtocol
        private let rateAsset: String = "USD"
        
        private var balanceId: String?
        private let originalAccountId: String
        
        // MARK: - Public properties
        
        var transactions: BehaviorRelay<Transactions> = BehaviorRelay(value: [])
        var loadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
        var loadingMoreStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
        
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
            reposController: ReposController,
            rateProvider: RateProviderProtocol,
            originalAccountId: String
            ) {
            
            self.reposController = reposController
            self.rateProvider = rateProvider
            self.originalAccountId = originalAccountId
            
            self.observeRateChanges()
        }
        
        // MARK: - Public
        
        func setBalanceId(_ balanceId: String) {
            guard self.balanceId != balanceId else {
                return
            }
            
            self.balanceId = balanceId
            self.transactionsHistoryRepo = self.reposController.getTransactionsHistoryRepo(for: balanceId)
            
            self.observeHistoryChanges()
            self.observeHistoryLoadingStatus()
            self.observeHistoryLoadingMoreStatus()
            self.observeHistoryErrorsStatus()
            
            self.reloadTransactions()
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
        
        func observeErrorStatus() -> Observable<Error> {
            return self.errorsStatus.asObservable()
        }
        
        func loadMoreTransactions() {
            self.transactionsHistoryRepo?.loadMoreHistory()
        }
        
        func reloadTransactions() {
            guard let transactionsHistoryRepo = self.transactionsHistoryRepo else {
                self.loadingStatus.accept(.loaded)
                return
            }
            
            transactionsHistoryRepo.reloadTransactions()
        }
        
        // MARK: - Private
        
        private func observeRateChanges() {
            self.rateProvider
                .rate
                .subscribe(onNext: { [weak self] (_) in
                    self?.transactionsDidChange()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeHistoryChanges() {
            self.trHistoryRepoTransactionsDisposable?.dispose()
            
            self.trHistoryRepoTransactionsDisposable = self.transactionsHistoryRepo?
                .observeHistory()
                .subscribe(onNext: { [weak self] (_) in
                    self?.transactionsDidChange()
                })
        }
        
        private func observeHistoryLoadingStatus() {
            self.trHistoryRepoLoadingStatusDisposable?.dispose()
            self.trHistoryRepoLoadingStatusDisposable =
                self.transactionsHistoryRepo?
                    .observeLoadingStatus()
                    .subscribe(onNext: { [weak self] (status) in
                        self?.loadingStatus.accept(status.status)
                    })
        }
        
        private func observeHistoryLoadingMoreStatus() {
            self.trHistoryRepoLoadingMoreStatusDisposable?.dispose()
            self.trHistoryRepoLoadingMoreStatusDisposable =
                self.transactionsHistoryRepo?
                    .observeLoadingStatus()
                    .subscribe(onNext: { [weak self] (status) in
                        self?.loadingMoreStatus.accept(status.status)
                    })
        }
        
        private func observeHistoryErrorsStatus() {
            self.trHistoryRepoErrorsStatusDisposable?.dispose()
            self.trHistoryRepoErrorsStatusDisposable =
                self.transactionsHistoryRepo?
                    .observeErrors()
                    .subscribe(onNext: { [weak self] (error) in
                        self?.errorsStatus.accept(error)
                    })
        }
        
        private func transactionsDidChange() {
            let effects = self.transactionsHistoryRepo?.history ?? []
            let transactions = self.parseEffects(effects)
            
            self.transactions.accept(transactions)
        }
        
        // MARK: Helpers
        
        private func parseEffects(_ effects: [ParticipantEffectResource]) -> Transactions {
            let transactions = effects.compactMap { (effect) -> Transaction? in
                return self.parseTransactionsFromEffect(effect)
            }
            return transactions
        }
        
        private func parseTransactionsFromEffect(_ participantEffect: ParticipantEffectResource) -> Transaction? {
            guard let effect = participantEffect.effect,
                let operation = participantEffect.operation else {
                    return nil
            }
            
            switch effect.effectType {
                
            case .effectBalanceChange(let balanceChangeEffect):
                return self.parseBalanceChnageEffect(
                    participantEffect: participantEffect,
                    balanceChangeEffect: balanceChangeEffect,
                    operation: operation
                )
                
            case .effectMatched(let matchedEffect):
                return self.parseMatchedEffect(
                    participantEffect: participantEffect,
                    matchedEffect: matchedEffect,
                    operation: operation
                )
                
            case .self:
                return nil
            }
        }
        
        private func parseBalanceChnageEffect(
            participantEffect: ParticipantEffectResource,
            balanceChangeEffect: EffectBalanceChangeResource,
            operation: OperationResource
            ) -> Transaction? {
            
            guard let balance = participantEffect.balance,
                let balanceId = balance.id,
                let assetResource = participantEffect.asset,
                let asset = assetResource.id,
                let id = participantEffect.id,
                let identifier = UInt64(id),
                let details = operation.details else {
                    return nil
            }
            
            let amount = TransactionsListScene.Model.Amount(
                value: balanceChangeEffect.amount,
                asset: asset
            )
            
            let amountEffect = self.getAmountEffect(balanceChangeEffect)
            
            let rateAmount = self.rateProvider.rateForAmount(
                balanceChangeEffect.amount,
                ofAsset: asset,
                destinationAsset: self.rateAsset
            )
            
            let rate = TransactionsListScene.Model.Amount(
                value: rateAmount ?? 0,
                asset: self.rateAsset
            )
            
            let counterparty = self.getCounterparty(details: details)
            
            let transaction = Transaction(
                identifier: identifier,
                balanceId: balanceId,
                amount: amount,
                amountEffect: amountEffect,
                counterparty: counterparty,
                rate: rate,
                date: operation.appliedAt
            )
            return transaction
        }
        
        private func parseMatchedEffect(
            participantEffect: ParticipantEffectResource,
            matchedEffect: EffectMatchedResource,
            operation: OperationResource
            ) -> Transaction? {
            
            guard let balance = participantEffect.balance,
                let balanceId = balance.id,
                let assetResource = participantEffect.asset,
                let asset = assetResource.id,
                let charged = matchedEffect.charged,
                let funded = matchedEffect.funded,
                let id = participantEffect.id,
                let identifier = UInt64(id) else {
                    return nil
            }
            
            let fundedInBalanceAsset = funded.assetCode == asset
            
            let amountValue = fundedInBalanceAsset ? funded.amount : charged.amount
            let amountAsset = fundedInBalanceAsset ? funded.assetCode : charged.assetCode
            
            let amount = TransactionsListScene.Model.Amount(
                value: amountValue,
                asset: amountAsset
            )
            
            let rateValue = self.rateProvider.rateForAmount(
                amountValue,
                ofAsset: amountAsset,
                destinationAsset: self.rateAsset
            )
            
            let rate = TransactionsListScene.Model.Amount(
                value: rateValue ?? 0,
                asset: self.rateAsset
            )
            
            let counterparty = matchedEffect.orderBookId == 0 ?
                Localized(.pending_offer) : Localized(.pending_investment)
            
            let transaction = Transaction(
                identifier: identifier,
                balanceId: balanceId,
                amount: amount,
                amountEffect: .matched,
                counterparty: counterparty,
                rate: rate,
                date: operation.appliedAt
            )
            return transaction
        }
        
        private func getAmountEffect(_ effect: EffectBalanceChangeResource) -> Transaction.AmountEffect {
            
            switch effect.effectBalanceChangeType {
                
            case .effectCharged:
                return .charged
                
            case .effectChargedFromLocked:
                return .charged_from_locked
                
            case .effectFunded:
                return .funded
                
            case .effectIssued:
                return .issued
                
            case .effectLocked:
                return .locked
                
            case .effectUnlocked:
                return .unlocked
                
            case .effectWithdrawn:
                return .withdrawn
                
            case .`self`:
                return .no_effect
            }
        }
        
        private func getCounterparty(details: OperationDetailsResource) -> String? {
            if let manageOfferDetails = details as? OpManageOfferDetailsResource {
                return manageOfferDetails.orderBookId == 0 ?
                    Localized(.pending_offer) : Localized(.pending_investment)
            } else if details as? OpManageAssetPairDetailsResource != nil {
                return Localized(.manage_asset_pair)
            } else if details as? OpCheckSaleStateDetailsResource != nil {
                return Localized(.investment_cancellation)
            } else {
                switch details.operationDetailsRelatedToBalance {
                    
                case .opCreateWithdrawRequestDetails:
                    return Localized(.withdrawal)
                    
                case .opPaymentDetails:
                    return Localized(.payment)
                    
                case .opCreateIssuanceRequestDetails:
                    return Localized(.issuance)
                    
                case .opCreateAMLAlertRequestDetails:
                    return Localized(.aml_alert_request)
                    
                case .opPayoutDetails:
                    return Localized(.payout)
                    
                case .`self`,
                     .opCreateAtomicSwapBidRequestDetails:
                    
                    return nil
                }
            }
        }
    }
}

private extension TransactionsHistoryRepo.LoadingStatus {
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
