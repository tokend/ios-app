import Foundation

public protocol DashboardScenePresentationLogic {
    
    typealias Event = DashboardScene.Event
    
    func presentSceneDidUpdate(response: Event.SceneDidUpdate.Response)
    func presentSceneDidUpdateSync(response: Event.SceneDidUpdateSync.Response)
}

extension DashboardScene {
    
    public typealias PresentationLogic = DashboardScenePresentationLogic
    
    @objc(DashboardScenePresenter)
    public class Presenter: NSObject {
        
        public typealias Event = DashboardScene.Event
        public typealias Model = DashboardScene.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        
        // MARK: -
        
        public init(
            presenterDispatch: PresenterDispatch
        ) {
            
            self.presenterDispatch = presenterDispatch
        }
    }
}

// MARK: - Private methods

private extension DashboardScene.Presenter {
    
    func mapSceneModel(_ sceneModel: Model.SceneModel) -> Model.SceneViewModel {
        
        return .init(
            isLoading: sceneModel.loadingStatus == .loading,
            content: .empty
        )
    }
}

// MARK: - PresenterLogic

extension DashboardScene.Presenter: DashboardScene.PresentationLogic {
    
    public func presentSceneDidUpdate(response: Event.SceneDidUpdate.Response) {
        let viewModel = mapSceneModel(response.sceneModel)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySceneDidUpdate(
                viewModel: .init(
                    viewModel: viewModel,
                    animated: response.animated
                )
            )
        }
    }
    
    public func presentSceneDidUpdateSync(response: Event.SceneDidUpdateSync.Response) {
        let viewModel = mapSceneModel(response.sceneModel)
        self.presenterDispatch.displaySync { (displayLogic) in
            displayLogic.displaySceneDidUpdateSync(
                viewModel: .init(
                    viewModel: viewModel,
                    animated: response.animated
                )
            )
        }
    }
}
