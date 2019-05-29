import Foundation
import TokenDSDK
import RxCocoa
import RxSwift

extension TransactionsListScene {
    
    class MovementsProvider: TransactionsProviderProtocol {
        
        // MARK: - Private properties
        
        private var movementsRepo: MovementsRepo
        
        private let loadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
        private let loadingMoreStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
        private let errorsStatus: PublishRelay<Swift.Error> = PublishRelay()
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        // MARK: -
        
        init(movementsRepo: MovementsRepo) {
            self.movementsRepo = movementsRepo
            
            self.observeRepoLoadingStatus()
            self.observeRepoLoadingMoreStatus()
            self.observeRepoErrors()
            
            self.movementsRepo.reloadTransactions()
        }
        
        // MARK: - Private
        
        private func observeRepoLoadingStatus() {
            self.movementsRepo
                .observeLoadingStatus()
                .subscribe(onNext: { [weak self] (status) in
                    self?.loadingStatus.accept(status.status)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeRepoLoadingMoreStatus() {
            self.movementsRepo
                .observeLoadingStatus()
                .subscribe(onNext: { [weak self] (status) in
                    self?.loadingMoreStatus.accept(status.status)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeRepoErrors() {
            self.movementsRepo
                .observeErrors()
                .subscribe(onNext: { [weak self] (error) in
                    self?.errorsStatus.accept(error)
                })
                .disposed(by: self.disposeBag)
        }
        
        // MARK: - TransactionsProviderProtocol
        
        func observeParicipantEffects() -> Observable<[ParticipantEffectResource]> {
            return self.movementsRepo.observeMovements()
        }
        
        func observeLoadingStatus() -> Observable<TransactionsListSceneTransactionsFetcherProtocol.LoadingStatus> {
            return self.loadingStatus.asObservable()
        }
        
        func observeLoadingMoreStatus() -> Observable<TransactionsListSceneTransactionsFetcherProtocol.LoadingStatus> {
            return self.loadingMoreStatus.asObservable()
        }
        
        func observeErrors() -> Observable<Error> {
            return self.errorsStatus.asObservable()
        }
        
        func loadMoreParicipantEffects() {
            self.movementsRepo.loadMoreMovements()
        }
        
        func reloadParicipantEffects() {
            self.movementsRepo.reloadTransactions()
        }
        
        func setBalanceId(_ balanceId: String) {
            
        }
    }
}

private extension MovementsRepo.LoadingStatus {
    var status: TransactionsListSceneTransactionsFetcherProtocol.LoadingStatus {
        switch self {
        case .loading:
            return .loading
        case .loaded:
            return .loaded
        }
    }
}
