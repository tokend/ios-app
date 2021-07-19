import Foundation

public protocol SignInScenePresentationLogic {
    
    typealias Event = SignInScene.Event
    
    func presentSceneDidUpdate(response: Event.SceneDidUpdate.Response)
    func presentSceneDidUpdateSync(response: Event.SceneDidUpdateSync.Response)
    func presentDidTapLoginButtonSync(response: Event.DidTapLoginButtonSync.Response)
}

extension SignInScene {
    
    public typealias PresentationLogic = SignInScenePresentationLogic
    
    @objc(SignInScenePresenter)
    public class Presenter: NSObject {
        
        public typealias Event = SignInScene.Event
        public typealias Model = SignInScene.Model
        
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

private extension SignInScene.Presenter {
    
    func mapSceneModel(_ sceneModel: Model.SceneModel) -> Model.SceneViewModel {
        
        let networkError: String?
        let loginError: String?
        let passwordError: String?
        
        switch sceneModel.networkError {
        case .emptyString:
            networkError = Localized(.validation_error_empty)
        case .none:
            networkError = nil
        }
        
        switch sceneModel.loginError {
        case .emptyString:
            loginError = Localized(.validation_error_empty)
        case .doesNotMatchRequirements:
            loginError = Localized(.sign_in_email_validation_error)
        case .none:
            loginError = nil
        }
        
        switch sceneModel.passwordError {
        case .emptyString:
            passwordError = Localized(.validation_error_empty)
        case .doesNotMatchRequirements:
            passwordError = Localized(.sign_in_invalid_password_error)
        case .none:
            passwordError = nil
        }
        
        
        return .init(
            network: sceneModel.network,
            login: sceneModel.login,
            password: sceneModel.password,
            networkError: networkError,
            loginError: loginError,
            passwordError: passwordError
        )
    }
}

// MARK: - PresenterLogic

extension SignInScene.Presenter: SignInScene.PresentationLogic {
    
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
    
    public func presentDidTapLoginButtonSync(response: Event.DidTapLoginButtonSync.Response) {
        let viewModel: Event.DidTapLoginButtonSync.ViewModel = response
        self.presenterDispatch.displaySync { (displayLogic) in
            displayLogic.displayDidTapLoginButtonSync(viewModel: viewModel)
        }
    }
}
