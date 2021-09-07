import Foundation
import RxCocoa
import RxSwift

extension SendAmountScene {
    class SelectedBalanceProvider {
        
        // MARK: - Private properties
        
        private let selectedBalanceBehaviorRelay: BehaviorRelay<SendAmountScene.Model.Balance>
        private let loadingStatusBehaviorRelay: BehaviorRelay<SendAmountScene.Model.LoadingStatus> = .init(value: .loading)
//        private let balancesRepo: BalancesRepo
//        private let selectedBalanceId: String
        
        private let disposeBag: DisposeBag = .init()
        private var shouldObserveRepos: Bool = true
        
        // MARK: -
         
        init(
            selectedBalance: SendAmountScene.Model.Balance
        ) {
            selectedBalanceBehaviorRelay = .init(value: selectedBalance)
        }
    }
}

// MARK: - Private methods

private extension SendAmountScene.SelectedBalanceProvider {
    
    func observeRepo() {
//        if shouldObserveRepos {
//            shouldObserveRepos = false
//            observeBalancesList()
//            observeReposLoadingStatus()
//        }
    }
    
    func observeBalancesList() {
//        balancesRepo
//            .observeBalancesDetails()
//            .subscribe(onNext: { [weak self] (balances) in
//
//                guard let balance = balances.first(where: {
//
//                    switch $0 {
//
//                    case .creating:
//                        return false
//
//                    case .created(let balance):
//                        return balance.id == self?.selectedBalanceId
//                    }
//                })
//                else {
//                    return
//                }
//
//                self?.selectedBalanceBehaviorRelay.accept(try? balance.mapToBalance())
//            })
//            .disposed(by: disposeBag)
    }
    
    func observeReposLoadingStatus() {
//        balancesRepo
//            .observeLoadingStatus()
//            .subscribe(onNext: { [weak self] (loadingStatus) in
//                if loadingStatus == .loaded {
//                    self?.loadingStatusBehaviorRelay.accept(.loaded)
//                } else {
//                    self?.loadingStatusBehaviorRelay.accept(.loading)
//                }
//            })
//            .disposed(by: disposeBag)
    }
}

// MARK: - Mappers

private enum SelectedBalanceProviderMapperError: Swift.Error {
    case noBalance
}

private extension BalancesRepo.BalanceState {
    func mapToBalance(
    ) throws -> SendAmountScene.Model.Balance {
        
        switch self {
        
        case .creating:
            throw SelectedBalanceProviderMapperError.noBalance
            
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
