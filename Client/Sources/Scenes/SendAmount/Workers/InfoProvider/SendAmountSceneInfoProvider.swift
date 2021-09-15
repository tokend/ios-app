import Foundation
import TokenDSDK
import RxCocoa
import RxSwift

extension SendAmountScene {
    class InfoProviderProvider {
        
        typealias OnFailedToFetchSelectedBalance = (Swift.Error) -> Void
        
        // MARK: - Private properties
        
        private let onFailedToFetchSelectedBalance: OnFailedToFetchSelectedBalance
        
        private let recipientAccountId: String
        private let recipientAddressValue: String
        private let selectedBalanceBehaviorRelay: BehaviorRelay<SendAmountScene.Model.Balance>
        private let feesBehaviorRelay: BehaviorRelay<SendAmountScene.Model.Fees> = .init(
            value: .init(senderFee: 0, recipientFee: 0)
        )
        private let feesLoadingStatusBehaviorRelay: BehaviorRelay<SendAmountScene.Model.LoadingStatus> = .init(value: .loaded)

        private let selectedBalanceId: String
        private let balancesRepo: BalancesRepo
        private let feesProcessor: FeesProcessorProtocol
        private let sendPaymentStorage: SendPaymentStorageProtocol
        
        private var shouldObserveRepos: Bool = true
        private let disposeBag: DisposeBag = .init()
        
        // MARK: -
         
        init(
            recipientAccountId: String,
            recipientEmail: String?,
            feesProcessor: FeesProcessorProtocol,
            balancesRepo: BalancesRepo,
            selectedBalanceId: String,
            sendPaymentStorage: SendPaymentStorageProtocol,
            onFailedToFetchSelectedBalance: @escaping OnFailedToFetchSelectedBalance
        ) throws {
            
            let selectedBalance = try balancesRepo.balancesDetails.fetchBalance(
                selectedBalanceId: selectedBalanceId
            )
            
            self.recipientAccountId = recipientAccountId
            self.recipientAddressValue = recipientEmail ?? recipientAccountId
            self.feesProcessor = feesProcessor
            self.balancesRepo = balancesRepo
            self.selectedBalanceId = selectedBalanceId
            self.sendPaymentStorage = sendPaymentStorage
            self.onFailedToFetchSelectedBalance = onFailedToFetchSelectedBalance
            
            selectedBalanceBehaviorRelay = .init(value: selectedBalance)
        }
    }
}

// MARK: - Private methods

private extension SendAmountScene.InfoProviderProvider {
    
    func observeIfNeeded() {
        if shouldObserveRepos {
            shouldObserveRepos = false
            observeBalancesList()
        }
    }
    
    func observeBalancesList() {
        balancesRepo
            .observeBalancesDetails()
            .subscribe(onNext: { [weak self] (balances) in
                
                guard let selectedBalanceId = self?.selectedBalanceId
                else {
                    return
                }
                
                do {
                    let newBalance = try balances.fetchBalance(
                        selectedBalanceId: selectedBalanceId
                    )
                    
                    if self?.selectedBalance != newBalance {
                        self?.selectedBalanceBehaviorRelay.accept(newBalance)
                    }
                } catch let error {
                    self?.onFailedToFetchSelectedBalance(error)
                }
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - Mappers

private enum InfoProviderError: Swift.Error {
    case noBalance
}

private extension Array where Element == BalancesRepo.BalanceState {
    
    func fetchBalance(
        selectedBalanceId: String
    ) throws -> SendAmountScene.Model.Balance {
        
        guard let balance = self.first(where: {

            switch $0 {

            case .creating:
                return false

            case .created(let balance):
                return balance.id == selectedBalanceId
            }
        })
        else {
            throw InfoProviderError.noBalance
        }
        
        return try balance.mapToBalance()
    }
}

private extension BalancesRepo.BalanceState {
    func mapToBalance(
    ) throws -> SendAmountScene.Model.Balance {
        
        switch self {
        
        case .creating:
            throw InfoProviderError.noBalance
            
        case .created(let balance):
            
            return .init(
                id: balance.id,
                assetCode: balance.asset.id,
                amount: balance.balance
            )
        }
    }
}

private extension FeesProcessorFeesModel {
    
    func mapToFees() -> SendAmountScene.Model.Fees {
        
        return .init(
            senderFee: self.senderFee.mapToFee(),
            recipientFee: self.recipientFee.mapToFee()
        )
    }
}

private extension Horizon.CalculatedFeeResource {
    
    func mapToFee() -> Decimal {
        
        return self.calculatedPercent + self.fixed
    }
}

// MARK: - SendAmountSceneBalancesProviderProtocol

extension SendAmountScene.InfoProviderProvider: SendAmountScene.InfoProviderProtocol {
    
    var recipientAddress: String {
        return recipientAddressValue
    }
    
    var selectedBalance: SendAmountScene.Model.Balance {
        return selectedBalanceBehaviorRelay.value
    }
    
    var fees: SendAmountScene.Model.Fees {
        return feesBehaviorRelay.value
    }
    
    var feesLoadingStatus: SendAmountScene.Model.LoadingStatus {
        return feesLoadingStatusBehaviorRelay.value
    }
    
    func observeBalance() -> Observable<SendAmountScene.Model.Balance> {
        observeIfNeeded()
        return selectedBalanceBehaviorRelay.asObservable()
    }
    
    func observeFees() -> Observable<SendAmountScene.Model.Fees> {
        observeIfNeeded()
        return feesBehaviorRelay.asObservable()
    }
    
    func observeFeesLoadingStatus() -> Observable<SendAmountScene.Model.LoadingStatus> {
        observeIfNeeded()
        return feesLoadingStatusBehaviorRelay.asObservable()
    }
    
    func calculateFees(
        for amount: Decimal,
        assetId: String
    ) {
        feesLoadingStatusBehaviorRelay.accept(.loading)
        
        feesProcessor.processFees(
            for: self.recipientAccountId,
            amount: amount,
            assetId: assetId,
            completion: { [weak self] (result) in
                
                switch result {
                
                case .success(let fees):
                    self?.sendPaymentStorage.updatePaymentModel(
                        sourceBalanceId: nil,
                        assetCode: nil,
                        destinationAccountId: nil,
                        recipientEmail: nil,
                        amount: amount,
                        senderFee: fees.senderFee,
                        recipientFee: fees.recipientFee,
                        isPayingFeeForRecipient: nil,
                        description: nil
                    )
                    self?.feesBehaviorRelay.accept(fees.mapToFees())
                    
                case .failure:
                    // TODO: - Handle errors
                    break
                }
                
                self?.feesLoadingStatusBehaviorRelay.accept(.loaded)
            }
        )
    }
}
