import Foundation

public protocol AccountIDScenePresentationLogic {
    
    typealias Event = AccountIDScene.Event
    
    func presentSceneDidUpdate(response: Event.SceneDidUpdate.Response)
    func presentSceneDidUpdateSync(response: Event.SceneDidUpdateSync.Response)
    func presentDidTapShareSync(response: Event.DidTapShareSync.Response)
}

extension AccountIDScene {
    
    public typealias PresentationLogic = AccountIDScenePresentationLogic
    
    @objc(AccountIDScenePresenter)
    public class Presenter: NSObject {
        
        public typealias Event = AccountIDScene.Event
        public typealias Model = AccountIDScene.Model
        
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

private extension AccountIDScene.Presenter {
    
    func mapSceneModel(_ sceneModel: Model.SceneModel) -> Model.SceneViewModel {
        
        return .init(
            qrCodeValue: sceneModel.accountId.uppercased()
        )
    }
}

// MARK: - PresenterLogic

extension AccountIDScene.Presenter: AccountIDScene.PresentationLogic {
    
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
    
    public func presentDidTapShareSync(response: Event.DidTapShareSync.Response) {
        let viewModel: Event.DidTapShareSync.ViewModel = .init(
            value: response.value
        )
        self.presenterDispatch.displaySync { displayLogic in
            displayLogic.displayDidTapShareSync(viewModel: viewModel)
        }
    }
}
