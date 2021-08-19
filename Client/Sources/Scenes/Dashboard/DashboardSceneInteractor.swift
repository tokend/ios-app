import Foundation
import RxSwift
import RxCocoa

public protocol DashboardSceneBusinessLogic {
    
    typealias Event = DashboardScene.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request)
    func onDidRefresh(request: Event.DidRefresh.Request)
}

extension DashboardScene {
    
    public typealias BusinessLogic = DashboardSceneBusinessLogic
    
    @objc(DashboardSceneInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = DashboardScene.Event
        public typealias Model = DashboardScene.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private var sceneModel: Model.SceneModel
        private let balancesProvider: BalancesProviderProtocol
        
        private let disposeBag: DisposeBag = .init()
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic,
            balancesProvider: BalancesProviderProtocol
        ) {
            
            self.presenter = presenter
            self.balancesProvider = balancesProvider
            
            self.sceneModel = .init(
                loadingStatus: .loaded,
                balancesList: balancesProvider.balances
            )
        }
    }
}

// MARK: - Private methods

private extension DashboardScene.Interactor {
    
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
    
    func observeBalancesList() {
        balancesProvider
            .observeBalances()
            .subscribe(onNext: { [weak self] (balances) in
                self?.sceneModel.balancesList = balances
                self?.presentSceneDidUpdate(animated: true)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - BusinessLogic

extension DashboardScene.Interactor: DashboardScene.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        observeBalancesList()
    }
    
    public func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request) {
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidRefresh(request: Event.DidRefresh.Request) {
        balancesProvider.initiateReload()
    }
}
