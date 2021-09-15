import Foundation
import RxCocoa
import RxSwift

extension SendAmountScene {
    class InfoProviderProvider {
        
        typealias OnFailedToFetchSelectedBalance = (Swift.Error) -> Void
        
        // MARK: - Private properties
        
        private let onFailedToFetchSelectedBalance: OnFailedToFetchSelectedBalance
        
        private let recipientAddressValue: String
        private let selectedBalanceBehaviorRelay: BehaviorRelay<SendAmountScene.Model.Balance>
        private let balancesRepo: BalancesRepo
        private let selectedBalanceId: String
        
        private let disposeBag: DisposeBag = .init()
        private var shouldObserveRepos: Bool = true
        
        // MARK: -
         
        init(
            recipientAccountId: String,
            recipientEmail: String?,
            balancesRepo: BalancesRepo,
            selectedBalanceId: String,
            onFailedToFetchSelectedBalance: @escaping OnFailedToFetchSelectedBalance
        ) throws {
            
            let selectedBalance = try balancesRepo.balancesDetails.fetchBalance(
                selectedBalanceId: selectedBalanceId
            )
            
            self.recipientAddressValue = recipientEmail ?? recipientAccountId
            self.balancesRepo = balancesRepo
            self.selectedBalanceId = selectedBalanceId
            self.onFailedToFetchSelectedBalance = onFailedToFetchSelectedBalance
            
            selectedBalanceBehaviorRelay = .init(value: selectedBalance)
        }
    }
}

// MARK: - Private methods

private extension SendAmountScene.InfoProviderProvider {
    
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

// MARK: - SendAmountSceneBalancesProviderProtocol

extension SendAmountScene.InfoProviderProvider: SendAmountScene.InfoProviderProtocol {
    
    var recipientAddress: String {
        return recipientAddressValue
    }
    
    var selectedBalance: SendAmountScene.Model.Balance {
        selectedBalanceBehaviorRelay.value
    }
    
    func observeBalance() -> Observable<SendAmountScene.Model.Balance> {
        if shouldObserveRepos {
            shouldObserveRepos = false
            observeBalancesList()
        }
        return selectedBalanceBehaviorRelay.asObservable()
    }
}
