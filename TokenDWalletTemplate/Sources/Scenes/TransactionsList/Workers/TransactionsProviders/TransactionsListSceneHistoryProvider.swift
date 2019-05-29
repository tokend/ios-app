import Foundation
import RxCocoa
import RxSwift
import TokenDSDK

extension TransactionsListScene {
    class HistoryProvider: TransactionsProviderProtocol {
        
        // MARK: - Private properties
        
        private var transactionsHistoryRepo: TransactionsHistoryRepo?
        private let errorsStatus: PublishRelay<Swift.Error> = PublishRelay()
        
        private var trHistoryRepoTransactionsDisposable: Disposable?
        private var trHistoryRepoLoadingStatusDisposable: Disposable?
        private var trHistoryRepoLoadingMoreStatusDisposable: Disposable?
        private var trHistoryRepoErrorsStatusDisposable: Disposable?
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        private let reposController: ReposController
        
        private var balanceId: String?
        private let originalAccountId: String
        
        // MARK: - Public properties
        
        private let effects: BehaviorRelay<[ParticipantEffectResource]> = BehaviorRelay(value: [])
        
        private let loadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
        private let loadingMoreStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
        
        // MARK: -
        
        init(
            reposController: ReposController,
            originalAccountId: String
            ) {
            
            self.reposController = reposController
            self.originalAccountId = originalAccountId
        }
        
        // MARK: - Public
        
        func observeParicipantEffects() -> Observable<[ParticipantEffectResource]> {
            return self.effects.asObservable()
        }
        
        func setBalanceId(_ balanceId: String) {
            guard self.balanceId != balanceId else {
                return
            }
            
            self.balanceId = balanceId
            self.transactionsHistoryRepo = self.reposController.getTransactionsHistoryRepo(for: balanceId)
            
            self.observeHistoryChanges()
            self.observeHistoryLoadingStatus()
            self.observeHistoryLoadingMoreStatus()
            self.observeHistoryErrorsStatus()
            
            self.reloadParicipantEffects()
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
            self.transactionsHistoryRepo?.loadMoreHistory()
        }
        
        func reloadParicipantEffects() {
            guard let transactionsHistoryRepo = self.transactionsHistoryRepo else {
                self.loadingStatus.accept(.loaded)
                return
            }
            
            transactionsHistoryRepo.reloadTransactions()
        }
        
        // MARK: - Private
        
        private func observeHistoryChanges() {
            self.trHistoryRepoTransactionsDisposable?.dispose()
            
            self.trHistoryRepoTransactionsDisposable = self.transactionsHistoryRepo?
                .observeHistory()
                .subscribe(onNext: { [weak self] (effects) in
                    self?.effects.accept(effects)
                })
        }
        
        private func observeHistoryLoadingStatus() {
            self.trHistoryRepoLoadingStatusDisposable?.dispose()
            self.trHistoryRepoLoadingStatusDisposable =
                self.transactionsHistoryRepo?
                    .observeLoadingStatus()
                    .subscribe(onNext: { [weak self] (status) in
                        self?.loadingStatus.accept(status.status)
                    })
        }
        
        private func observeHistoryLoadingMoreStatus() {
            self.trHistoryRepoLoadingMoreStatusDisposable?.dispose()
            self.trHistoryRepoLoadingMoreStatusDisposable =
                self.transactionsHistoryRepo?
                    .observeLoadingStatus()
                    .subscribe(onNext: { [weak self] (status) in
                        self?.loadingMoreStatus.accept(status.status)
                    })
        }
        
        private func observeHistoryErrorsStatus() {
            self.trHistoryRepoErrorsStatusDisposable?.dispose()
            self.trHistoryRepoErrorsStatusDisposable =
                self.transactionsHistoryRepo?
                    .observeErrors()
                    .subscribe(onNext: { [weak self] (error) in
                        self?.errorsStatus.accept(error)
                    })
        }
    }
}

private extension TransactionsHistoryRepo.LoadingStatus {
    var status: TransactionsListSceneTransactionsFetcherProtocol.LoadingStatus {
        switch self {
        case .loading:
            return .loading
        case .loaded:
            return .loaded
        }
    }
}
