import Foundation
import RxCocoa
import RxSwift
import TokenDSDK

extension TransactionsListScene {
    class PaymentsFetcher: TransactionsFetcherProtocol {
        
        // MARK: - Private properties
        
        private let transactionsProvider: TransactionsProviderProtocol
        private var effects: [ParticipantEffectResource] = []
        private let disposeBag: DisposeBag = DisposeBag()
        
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
        
        init(transactionsProvider: TransactionsProviderProtocol) {
            self.transactionsProvider = transactionsProvider
            
            self.observeEffects()
            self.observeTransactionsLoadingStatus()
            self.observeTransactionsLoadingMoreStatus()
        }
        
        // MARK: - Public
        
        func setBalanceId(_ balanceId: String) {
            self.transactionsProvider.setBalanceId(balanceId)
        }
        
        func observeTransactions() -> Observable<TransactionsListSceneTransactionsFetcherProtocol.Transactions> {
            return self.transactions.asObservable()
        }
        
        func observeLoadingStatus() -> Observable<TransactionsListSceneTransactionsFetcherProtocol.LoadingStatus> {
            return self.transactionsProvider.observeLoadingStatus()
        }
        
        func observeLoadingMoreStatus() -> Observable<TransactionsListSceneTransactionsFetcherProtocol.LoadingStatus> {
            return self.transactionsProvider.observeLoadingMoreStatus()
        }
        
        func observeErrorStatus() -> Observable<Error> {
            return self.transactionsProvider.observeErrors()
        }
        
        func loadMoreTransactions() {
            self.transactionsProvider.loadMoreParicipantEffects()
        }
        
        func reloadTransactions() {
            self.transactionsProvider.reloadParicipantEffects()
        }
        
        // MARK: - Private
        
        private func observeEffects() {
            self.transactionsProvider
                .observeParicipantEffects()
                .subscribe(onNext: { [weak self] (effects) in
                    self?.effects = effects
                    self?.transactionsDidChange()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeTransactionsLoadingStatus() {
            self.transactionsProvider
                .observeLoadingStatus()
                .subscribe(onNext: { [weak self] (status) in
                    self?.loadingStatus.accept(status)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeTransactionsLoadingMoreStatus() {
            self.transactionsProvider
                .observeLoadingMoreStatus()
                .subscribe(onNext: { [weak self] (status) in
                    self?.loadingMoreStatus.accept(status)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func transactionsDidChange() {
            let transactions = self.parseEffects(self.effects)
            
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
            
            let counterparty = self.getCounterparty(details: details)
            
            let transaction = Transaction(
                identifier: identifier,
                balanceId: balanceId,
                amount: amount,
                amountEffect: amountEffect,
                counterparty: counterparty,
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
            
            let counterparty = matchedEffect.orderBookId == 0 ?
                Localized(.pending_order) : Localized(.pending_investment)
            
            let transaction = Transaction(
                identifier: identifier,
                balanceId: balanceId,
                amount: amount,
                amountEffect: .matched,
                counterparty: counterparty,
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
                    Localized(.pending_order) : Localized(.pending_investment)
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

private typealias Transaction = TransactionsListScene.Model.Transaction
private typealias Amount = TransactionsListScene.Model.Amount
