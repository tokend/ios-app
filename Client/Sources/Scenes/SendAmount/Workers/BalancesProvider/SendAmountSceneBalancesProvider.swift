import Foundation
import RxCocoa
import RxSwift

extension SendAmountScene {
    class SelectedBalanceProvider {
        
        typealias OnFailedToFetchSelectedBalance = (Swift.Error) -> Void
        
        // MARK: - Private properties
        
        private let onFailedToFetchSelectedBalance: OnFailedToFetchSelectedBalance
        
        private let selectedBalanceBehaviorRelay: BehaviorRelay<SendAmountScene.Model.Balance>
        private let loadingStatusBehaviorRelay: BehaviorRelay<SendAmountScene.Model.LoadingStatus> = .init(value: .loading)
        private let balancesRepo: BalancesRepo
        private let selectedBalanceId: String
        
        private let disposeBag: DisposeBag = .init()
        private var shouldObserveRepos: Bool = true
        
        // MARK: -
         
        init(
            balancesRepo: BalancesRepo,
            selectedBalanceId: String,
            onFailedToFetchSelectedBalance: @escaping OnFailedToFetchSelectedBalance
        ) throws {
            
            let selectedBalance = try balancesRepo.balancesDetails.fetchBalance(
                selectedBalanceId: selectedBalanceId
            )
            
            self.balancesRepo = balancesRepo
            self.selectedBalanceId = selectedBalanceId
            self.onFailedToFetchSelectedBalance = onFailedToFetchSelectedBalance
            
            selectedBalanceBehaviorRelay = .init(value: selectedBalance)
        }
    }
}

// MARK: - Private methods

private extension SendAmountScene.SelectedBalanceProvider {
    
    func observeRepo() {
        if shouldObserveRepos {
            shouldObserveRepos = false
            observeBalancesList()
            observeReposLoadingStatus()
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
                    let selectedBalance = try balances.fetchBalance(
                        selectedBalanceId: selectedBalanceId
                    )
                    
                    self?.selectedBalanceBehaviorRelay.accept(selectedBalance)
                } catch let error {
                    self?.onFailedToFetchSelectedBalance(error)
                }
            })
            .disposed(by: disposeBag)
    }
    
    func observeReposLoadingStatus() {
        balancesRepo
            .observeLoadingStatus()
            .subscribe(onNext: { [weak self] (loadingStatus) in
                if loadingStatus == .loaded {
                    self?.loadingStatusBehaviorRelay.accept(.loaded)
                } else {
                    self?.loadingStatusBehaviorRelay.accept(.loading)
                }
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - Mappers

private enum SelectedBalanceProviderError: Swift.Error {
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
            throw SelectedBalanceProviderError.noBalance
        }
        
        return try balance.mapToBalance()
    }
}

private extension BalancesRepo.BalanceState {
    func mapToBalance(
    ) throws -> SendAmountScene.Model.Balance {
        
        switch self {
        
        case .creating:
            throw SelectedBalanceProviderError.noBalance
            
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

extension SendAmountScene.SelectedBalanceProvider: SendAmountScene.SelectedBalanceProviderProtocol {
    var selectedBalance: SendAmountScene.Model.Balance {
        selectedBalanceBehaviorRelay.value
    }
    
    func observeBalance() -> Observable<SendAmountScene.Model.Balance> {
        observeRepo()
        return selectedBalanceBehaviorRelay.asObservable()
    }
}
