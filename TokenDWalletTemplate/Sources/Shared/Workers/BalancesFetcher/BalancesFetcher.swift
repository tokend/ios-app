import Foundation
import RxCocoa
import RxSwift

class BalancesFetcher {
    
    typealias Balance = BalancesRepo.BalanceState
    
    // MARK: - Private properties
    
    private let balancesRepo: BalancesRepo
    
    public let balancesBehaviorRelay: BehaviorRelay<[Balance]> = BehaviorRelay(value: [])
    public let balancesLoadingStatus: BehaviorRelay<BalancesRepo.LoadingStatus> = BehaviorRelay(value: .loaded)
    public let balancesErrorStatus: PublishRelay<Swift.Error> = PublishRelay()
    
    private let disposeBag: DisposeBag = DisposeBag()
    
    // MARK: -
    
    init(balancesRepo: BalancesRepo) {
        
        self.balancesRepo = balancesRepo
        
        self.observeBalancesRepo()
    }
    
    func refreshBalances() {
        self.balancesRepo.reloadBalancesDetails()
    }
    
    // MARK: - Private
    
    private func observeBalancesRepo() {
        self.balancesRepo
            .observeBalancesDetails()
            .subscribe(onNext: { (balancesDetails) in
                self.balancesBehaviorRelay.accept(balancesDetails)
            })
            .disposed(by: self.disposeBag)
    }
    
    private func observeBalancesLoadingStatus() {
        self.balancesRepo
            .observeLoadingStatus()
            .subscribe(onNext: { [weak self] (status) in
                self?.balancesLoadingStatus.accept(status)
            })
            .disposed(by: self.disposeBag)
    }
    
    private func observeBalancesErrorStatus() {
        self.balancesRepo
            .observeErrorStatus()
            .subscribe(onNext: { [weak self] (error) in
                self?.balancesErrorStatus.accept(error)
            })
            .disposed(by: self.disposeBag)
    }
}
