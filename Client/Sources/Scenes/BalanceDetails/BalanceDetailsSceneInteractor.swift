import Foundation
import RxSwift
import RxCocoa

public protocol BalanceDetailsSceneBusinessLogic {
    
    typealias Event = BalanceDetailsScene.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request)
    func onDidRefresh(request: Event.DidRefresh.Request)
}

extension BalanceDetailsScene {
    
    public typealias BusinessLogic = BalanceDetailsSceneBusinessLogic
    
    @objc(BalanceDetailsSceneInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = BalanceDetailsScene.Event
        public typealias Model = BalanceDetailsScene.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private var sceneModel: Model.SceneModel
        
        private let balanceProvider: BalanceProviderProtocol
        private let transactionsProvider: TransactionsProviderProtocol
        private let disposeBag: DisposeBag = .init()
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic,
            balanceProvider: BalanceProviderProtocol,
            transactionsProvider: TransactionsProviderProtocol
        ) {
            
            self.presenter = presenter
            self.sceneModel = .init(
                balance: balanceProvider.balance,
                loadingStatus: transactionsProvider.loadingStatus,
                transactions: transactionsProvider.transactions
            )
            
            self.balanceProvider = balanceProvider
            self.transactionsProvider = transactionsProvider
        }
    }
}

// MARK: - Private methods

private extension BalanceDetailsScene.Interactor {
    
    func observeTransactionsProvider() {
        
        transactionsProvider
            .observeTransactions()
            .subscribe(onNext: { [weak self] (transactions) in
                self?.sceneModel.transactions = transactions
                self?.presentSceneDidUpdate(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    func observeBalanceProvider() {
        
        balanceProvider
            .observeBalance()
            .subscribe(onNext: { [weak self] (balance) in
                self?.sceneModel.balance = balance
                self?.presentSceneDidUpdate(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    func observeLoadingStatus() {
        
        Observable.combineLatest(
            transactionsProvider.observeLoadingStatus(),
            balanceProvider.observeLoadingStatus()
        ).subscribe(onNext: { [weak self] (tuple) in
            
            if tuple.0 == .loaded && tuple.1 == .loaded {
                self?.sceneModel.loadingStatus = .loaded
            } else {
                self?.sceneModel.loadingStatus = .loading
            }
            self?.presentSceneDidUpdate(animated: true)
        })
        .disposed(by: disposeBag)
    }
    
    func presentSceneDidUpdate(animated: Bool) {
        let response: Event.SceneDidUpdate.Response = .init(
            sceneModel: sceneModel,
            animated: animated
        )
        presenter.presentSceneDidUpdate(response: response)
    }

    func presentSceneDidUpdateSync(animated: Bool) {
        let response: Event.SceneDidUpdateSync.Response = .init(
            sceneModel: sceneModel,
            animated: animated
        )
        presenter.presentSceneDidUpdateSync(response: response)
    }
}

// MARK: - BusinessLogic

extension BalanceDetailsScene.Interactor: BalanceDetailsScene.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        observeTransactionsProvider()
        observeBalanceProvider()
        observeLoadingStatus()
    }
    
    public func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request) {
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidRefresh(request: Event.DidRefresh.Request) {
        transactionsProvider.reloadTransactions()
        balanceProvider.reloadBalance()
    }
}
