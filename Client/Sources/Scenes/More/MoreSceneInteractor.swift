import Foundation
import RxSwift

public protocol MoreSceneBusinessLogic {
    
    typealias Event = MoreScene.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request)
    func onDidRefresh(request: Event.DidRefresh.Request)
    func onItemTapSync(request: Event.ItemTapSync.Request)
}

extension MoreScene {
    
    public typealias BusinessLogic = MoreSceneBusinessLogic
    
    @objc(MoreSceneInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = MoreScene.Event
        public typealias Model = MoreScene.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private var sceneModel: Model.SceneModel
        
        private let userDataProvider: UserDataProviderProtocol
        private let disposeBag: DisposeBag = .init()
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic,
            userDataProvider: UserDataProviderProtocol
        ) {
            
            self.presenter = presenter
            self.userDataProvider = userDataProvider
            
            self.sceneModel = .init(
                userData: userDataProvider.userData,
                loadingStatus: .loaded,
                items: [
                    .deposit,
                    .withdraw,
                    .exploreSales,
                    .trade,
                    .polls,
                    .settings
                ]
            )
        }
    }
}

// MARK: - Private methods

private extension MoreScene.Interactor {
    
    func observeUserDataProvider() {
        userDataProvider
            .observeUserData()
            .subscribe(onNext: { [weak self] (userData) in
                self?.sceneModel.userData = userData
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

extension MoreScene.Interactor: MoreScene.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        observeUserDataProvider()
    }
    
    public func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request) {
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidRefresh(request: Event.DidRefresh.Request) { }
    
    public func onItemTapSync(request: Event.ItemTapSync.Request) {
        
        guard let item = Model.Item(rawValue: request.id)
        else {
            return
        }
        
        let response: Event.ItemTapSync.Response = .init(
            item: item
        )
        presenter.presentItemTapSync(response: response)
    }
}
