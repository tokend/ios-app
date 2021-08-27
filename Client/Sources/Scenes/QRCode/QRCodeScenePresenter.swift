import Foundation

public protocol QRCodeScenePresentationLogic {
    
    typealias Event = QRCodeScene.Event
    
    func presentSceneDidUpdate(response: Event.SceneDidUpdate.Response)
    func presentSceneDidUpdateSync(response: Event.SceneDidUpdateSync.Response)
    func presentDidTapShareSync(response: Event.DidTapShareSync.Response)
}

extension QRCodeScene {
    
    public typealias PresentationLogic = QRCodeScenePresentationLogic
    
    @objc(QRCodeScenePresenter)
    public class Presenter: NSObject {
        
        public typealias Event = QRCodeScene.Event
        public typealias Model = QRCodeScene.Model
        
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

private extension QRCodeScene.Presenter {
    
    func mapSceneModel(_ sceneModel: Model.SceneModel) -> Model.SceneViewModel {
        
        return .init(
            screenTitle: sceneModel.title,
            qrCodeValue: sceneModel.data
        )
    }
}

// MARK: - PresenterLogic

extension QRCodeScene.Presenter: QRCodeScene.PresentationLogic {
    
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
        let viewModel: Event.DidTapShareSync.ViewModel = response
        self.presenterDispatch.displaySync { displayLogic in
            displayLogic.displayDidTapShareSync(viewModel: viewModel)
        }
    }
}
