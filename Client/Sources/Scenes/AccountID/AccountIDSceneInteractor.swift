import Foundation
import RxCocoa
import RxSwift

public protocol AccountIDSceneBusinessLogic {
    
    typealias Event = AccountIDScene.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request)
    func onDidTapShareSync(request: Event.DidTapShareSync.Request)
}

extension AccountIDScene {
    
    public typealias BusinessLogic = AccountIDSceneBusinessLogic
    
    @objc(AccountIDSceneInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = AccountIDScene.Event
        public typealias Model = AccountIDScene.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private var sceneModel: Model.SceneModel
        
        private let accountIdProvider: AccountIDProviderProtocol
        private let disposeBag: DisposeBag = .init()
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic,
            accountIdProvider: AccountIDProviderProtocol
        ) {
            
            self.presenter = presenter
            self.accountIdProvider = accountIdProvider
            
            self.sceneModel = .init(
                accountId: accountIdProvider.accountId
            )
        }
    }
}

// MARK: - Private methods

private extension AccountIDScene.Interactor {
    
    func observeAccountIdProvider() {
        
        accountIdProvider
            .observeAccountId()
            .subscribe(onNext: { [weak self] (accountId) in
                self?.sceneModel.accountId = accountId
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

extension AccountIDScene.Interactor: AccountIDScene.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        observeAccountIdProvider()
    }
    
    public func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request) {
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidTapShareSync(request: Event.DidTapShareSync.Request) {
        let response: Event.DidTapShareSync.Response = .init(
            value: sceneModel.accountId
        )
        self.presenter.presentDidTapShareSync(response: response)
    }
}
