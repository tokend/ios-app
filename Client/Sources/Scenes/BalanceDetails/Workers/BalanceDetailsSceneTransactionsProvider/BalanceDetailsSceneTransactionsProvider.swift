import Foundation
import RxSwift
import RxCocoa

extension BalanceDetailsScene {
    
    class TransactionsProvider {
        
        // MARK: Private properties
        
        private let movementsRepo: MovementsRepo
        private var shouldObserveRepo: Bool = true
        private let receiverAccountId: String
        
        private let transactionsBehaviorRelay: BehaviorRelay<[BalanceDetailsScene.Model.Transaction]> = .init(value: [])
        private let loadingStatusBehaviorRelay: BehaviorRelay<BalanceDetailsScene.Model.LoadingStatus> = .init(value: .loaded)
        private let disposeBag: DisposeBag = .init()
        
        // MARK:
        
        init(
            movementsRepo: MovementsRepo,
            receiverAccountId: String
        ) {
            
            self.movementsRepo = movementsRepo
            self.receiverAccountId = receiverAccountId
        }
    }
}

// MARK: Private methods

private extension BalanceDetailsScene.TransactionsProvider {
    
    func observeIfNeeded() {
        
        guard shouldObserveRepo else { return }
        
        movementsRepo
            .observeMovements()
            .subscribe(onNext: { [weak self] (movements) in
                self?.transactionsBehaviorRelay.accept(
                    movements.mapToTransactions(
                        receiverAccountId: self?.receiverAccountId ?? ""
                    )
                )
            })
            .disposed(by: disposeBag)
        
        movementsRepo
            .observeLoadingStatus()
            .subscribe(onNext: { [weak self] (loadingStatus) in
                self?.loadingStatusBehaviorRelay.accept(loadingStatus.mapToLoadingStatus())
            })
            .disposed(by: disposeBag)
    }
}

// MARK: Mapping

extension Array where Element == MovementsRepo.Movement {
    
    func mapToTransactions(
        receiverAccountId: String
    ) -> [BalanceDetailsScene.Model.Transaction] {
        
        compactMap({ (movement) in
            movement.mapToTransaction(
                receiverAccountId: receiverAccountId
            )
        })
    }
}

extension MovementsRepo.Movement {
    
    func mapToTransaction(
        receiverAccountId: String
    ) -> BalanceDetailsScene.Model.Transaction {
        
        return .init(
            id: self.id,
            amount: self.amount,
            asset: self.assetId,
            action: self.action.mapToTransactionAction(),
            transactionType: self.movementType.mapToTransactionType(
                receiverAccountId: receiverAccountId
            )
        )
    }
}

extension MovementsRepo.Movement.Action {
    
    func mapToTransactionAction(
    ) -> BalanceDetailsScene.Model.Transaction.Action {
        
        switch self {
        
        case .locked: return .locked
        case .chargedFromLocked: return .chargedFromLocked
        case .unlocked: return .unlocked
        case .charged: return .charged
        case .withdrawn: return .withdrawn
        case .matched: return .matched
        case .issued: return .issued
        case .funded: return .funded
        }
    }
}

extension MovementsRepo.Movement.MovementType {
    
    func mapToTransactionType(
        receiverAccountId: String
    ) -> BalanceDetailsScene.Model.Transaction.TransactionType {
        
        switch self {
        
        case .amlAlert: return .amlAlert
        case .offer: return .offer
        case .matchedOffer: return .matchedOffer
        case .investment: return .investment
        case .saleCancellation: return .saleCancellation
        case .offerCancellation: return .offerCancellation
        case .issuance: return .issuance
        case .payment(let payment):
            
            if receiverAccountId == payment.destinationAccountId {
                return .payment(
                    counterpartyAccountId: payment.sourceAccountId,
                    counterpartyName: nil
                )
            } else if receiverAccountId == payment.sourceAccountId {
                return .payment(
                    counterpartyAccountId: payment.destinationAccountId,
                    counterpartyName: nil
                )
            } else {
                return .payment(
                    counterpartyAccountId: "",
                    counterpartyName: nil
                )
            }
        case .withdrawalRequest(let withdraw):
            return .withdrawalRequest(destinationAccountId: withdraw.destinationAddress)
        case .assetPairUpdate: return .assetPairUpdate
        case .atomicSwapAskCreation: return .atomicSwapAskCreation
        case .atomicSwapBidCreation: return .atomicSwapBidCreation
        }
    }
}

extension MovementsRepo.LoadingStatus {
    
    func mapToLoadingStatus() -> BalanceDetailsScene.Model.LoadingStatus {
        
        switch self {
        
        case .loaded:
            return .loaded
            
        case .loading:
            return .loading
        }
    }
}

// MARK: BalanceDetailsScene.TransactionsProviderProtocol

extension BalanceDetailsScene.TransactionsProvider: BalanceDetailsScene.TransactionsProviderProtocol {
    
    var transactions: [BalanceDetailsScene.Model.Transaction] {
        observeIfNeeded()
        return movementsRepo.movements.mapToTransactions(
            receiverAccountId: receiverAccountId
        )
    }
    
    var loadingStatus: BalanceDetailsScene.Model.LoadingStatus {
        observeIfNeeded()
        return movementsRepo.loadingStatus.mapToLoadingStatus()
    }
    
    func observeTransactions() -> Observable<[BalanceDetailsScene.Model.Transaction]> {
        observeIfNeeded()
        return transactionsBehaviorRelay.asObservable()
    }
    
    func observeLoadingStatus() -> Observable<BalanceDetailsScene.Model.LoadingStatus> {
        observeIfNeeded()
        return loadingStatusBehaviorRelay.asObservable()
    }
    
    func reloadTransactions() {
        movementsRepo.loadAllMovements(completion: nil)
    }
}
