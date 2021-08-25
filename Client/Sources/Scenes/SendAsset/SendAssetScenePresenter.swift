import Foundation

public protocol SendAssetScenePresentationLogic {
    
    typealias Event = SendAssetScene.Event
    
    func presentSceneDidUpdate(response: Event.SceneDidUpdate.Response)
    func presentSceneDidUpdateSync(response: Event.SceneDidUpdateSync.Response)
    func presentDidTapContinueSync(response: Event.DidTapContinueSync.Response)
}

extension SendAssetScene {
    
    public typealias PresentationLogic = SendAssetScenePresentationLogic
    
    @objc(SendAssetScenePresenter)
    public class Presenter: NSObject {
        
        public typealias Event = SendAssetScene.Event
        public typealias Model = SendAssetScene.Model
        
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

private extension SendAssetScene.Presenter {
    
    func mapSceneModel(_ sceneModel: Model.SceneModel) -> Model.SceneViewModel {
        
        let recipientError: String?
        
        switch sceneModel.recipientError {
        
        case .emptyString:
            recipientError = Localized(.validation_error_empty)
            
        case .none:
            recipientError = nil
        }
        
        return .init(
            recipientAddress: sceneModel.recipientAddress,
            recipientError: recipientError
        )
    }
}

// MARK: - PresenterLogic

extension SendAssetScene.Presenter: SendAssetScene.PresentationLogic {
    
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
    
    public func presentDidTapContinueSync(response: Event.DidTapContinueSync.Response) {
        let viewModel: Event.DidTapContinueSync.ViewModel = response
        self.presenterDispatch.displaySync { (displayLogic) in
            displayLogic.displayDidTapContinueSync(viewModel: viewModel)
        }
    }
}
