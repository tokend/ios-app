import UIKit

public protocol LocalSignInScenePresentationLogic {
    
    typealias Event = LocalSignInScene.Event
    
    func presentSceneDidUpdate(response: Event.SceneDidUpdate.Response)
    func presentSceneDidUpdateSync(response: Event.SceneDidUpdateSync.Response)
    func presentDidTapBiometricsSync(response: Event.DidTapBiometricsSync.Response)
    func presentDidTapLoginButtonSync(response: Event.DidTapLoginButtonSync.Response)
}

extension LocalSignInScene {
    
    public typealias PresentationLogic = LocalSignInScenePresentationLogic
    
    @objc(LocalSignInScenePresenter)
    public class Presenter: NSObject {
        
        public typealias Event = LocalSignInScene.Event
        public typealias Model = LocalSignInScene.Model
        
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

private extension LocalSignInScene.Presenter {
    
    func mapSceneModel(_ sceneModel: Model.SceneModel) -> Model.SceneViewModel {
        
        let biometricsTitle: String?
        let biometricsImage: UIImage?
        
        switch sceneModel.biometricsType {
        
        case .touchId:
            biometricsTitle = Localized(.touch_id_title)
            biometricsImage = Assets.touch_id_icon.image
            
        case .faceId:
            biometricsTitle = Localized(.face_id_title)
            biometricsImage = Assets.face_id_icon.image
            
        case .none:
            biometricsTitle = nil
            biometricsImage = nil
        }
        
        let passwordError: String?
        
        switch sceneModel.passwordError {
        
        case .none:
            passwordError = nil
        case .empty:
            passwordError = Localized(.validation_error_empty)
        }
        
        return .init(
            avatarUrl: sceneModel.avatarUrl,
            avatarTitle: String(sceneModel.login.prefix(1)),
            login: sceneModel.login,
            password: sceneModel.password,
            passwordError: passwordError,
            biometricsTitle: biometricsTitle,
            biometricsImage: biometricsImage
        )
    }
}

// MARK: - PresenterLogic

extension LocalSignInScene.Presenter: LocalSignInScene.PresentationLogic {
    
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
    
    public func presentDidTapBiometricsSync(response: Event.DidTapBiometricsSync.Response) {
        let viewModel: Event.DidTapBiometricsSync.ViewModel = response
        presenterDispatch.displaySync { (displayLogic) in
            displayLogic.displayDidTapBiometricsSync(viewModel: viewModel)
        }
    }
    
    public func presentDidTapLoginButtonSync(response: Event.DidTapLoginButtonSync.Response) {
        let viewModel: Event.DidTapLoginButtonSync.ViewModel = response
        presenterDispatch.displaySync { (displayLogic) in
            displayLogic.displayDidTapLoginButtonSync(viewModel: viewModel)
        }
    }
}
