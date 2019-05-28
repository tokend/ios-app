import Foundation
import RxCocoa
import RxSwift

protocol BalanceListBalanceFetcherProtocol {
    func observeBalances() -> Observable<[BalancesList.Model.Balance]>
    func observeLoadingStatus() -> Observable<BalancesList.Model.LoadingStatus>
}

extension BalancesList {
    typealias BalancesFetcherProtocol = BalanceListBalanceFetcherProtocol
    
    class BalancesFetcher {
        
        // MARK: - Private properties
        
        private let balancesRepo: BalancesRepo
        private let balancesRelay: BehaviorRelay<[Model.Balance]> = BehaviorRelay(value: [])
        
        private let loadingStatus: BehaviorRelay<Model.LoadingStatus> = BehaviorRelay(value: .loaded)
        private let disposeBag: DisposeBag = DisposeBag()
        
        // MARK: -
        
        init(balancesRepo: BalancesRepo) {
            self.balancesRepo = balancesRepo
        }
        
        // MARK: - Private
        
        private func observeBalancesRepo() {
            self.balancesRepo
                .observeBalancesDetails()
                .subscribe(onNext: { [weak self] (states) in
                    let balances = states.compactMap({ (state) -> BalancesRepo.BalanceDetails? in
                        switch state {
                            
                        case .created(let balance):
                            return balance
                            
                        case .creating:
                            return nil
                        }
                    })
                    self?.updateBalances(balances: balances)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func updateBalances(balances: [BalancesRepo.BalanceDetails]) {
            let updatedBalances = balances.map { (details) -> Model.Balance in
                return Model.Balance(
                    code: details.asset,
                    balance: details.balance,
                    balanceId: details.balanceId,
                    convertedBalance: details.convertedBalance
                )}
                .sorted(by: { (left, right) -> Bool in
                    return left.convertedBalance > right.convertedBalance
                })
            
            self.balancesRelay.accept(updatedBalances)
        }
    }
}

extension BalancesList.BalancesFetcher: BalancesList.BalancesFetcherProtocol {
    
    func observeBalances() -> Observable<[BalancesList.Model.Balance]> {
        self.observeBalancesRepo()
        
        return self.balancesRelay.asObservable()
    }
    
    func observeLoadingStatus() -> Observable<BalancesList.Model.LoadingStatus> {
        self.balancesRepo
            .observeLoadingStatus()
            .subscribe(onNext: { [weak self] (status) in
                switch status {
                case .loaded:
                    self?.loadingStatus.accept(.loaded)
                    
                case .loading:
                    self?.loadingStatus.accept(.loading)
                }
            })
            .disposed(by: self.disposeBag)
        
        return self.loadingStatus.asObservable()
    }
}
