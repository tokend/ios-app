import Foundation
import RxCocoa
import RxSwift

public protocol PollsBalanceFetcherProtocol {
    func observeBalances() -> Observable<[Polls.Model.Balance]>
    func observeLoadingStatus() -> Observable<Polls.Model.LoadingStatus>
}

extension Polls {
    public typealias BalancesFetcherProtocol = PollsBalanceFetcherProtocol
    
    public class BalancesFetcher {
        
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
                    let balances = states.compactMap({ (state) -> Model.Balance? in
                            switch state {
                                
                            case .created(let balance):
                                guard balance.balance > 0 else {
                                    return nil
                                }
                                return Model.Balance(
                                    asset: balance.asset,
                                    balanceId: balance.balanceId
                                )
                                
                            case .creating:
                                return nil
                            }
                        })
                    
                    self?.balancesRelay.accept(balances)
                })
                .disposed(by: self.disposeBag)   
        }
    }
}

extension Polls.BalancesFetcher: Polls.BalancesFetcherProtocol {
    
    public func observeBalances() -> Observable<[Polls.Model.Balance]> {
        self.observeBalancesRepo()
        
        return self.balancesRelay.asObservable()
    }
    
    public func observeLoadingStatus() -> Observable<Polls.Model.LoadingStatus> {
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
