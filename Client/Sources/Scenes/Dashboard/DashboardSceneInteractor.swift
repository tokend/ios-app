import Foundation

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
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic
        ) {
            
            self.presenter = presenter
            self.sceneModel = .init(
                loadingStatus: .loaded
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
}

// MARK: - BusinessLogic

extension DashboardScene.Interactor: DashboardScene.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) { }
    
    public func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request) {
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidRefresh(request: Event.DidRefresh.Request) { }
}
