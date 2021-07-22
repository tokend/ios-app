import Foundation

public protocol SignUpScenePresentationLogic {
    
    typealias Event = SignUpScene.Event
    
    func presentSceneDidUpdate(response: Event.SceneDidUpdate.Response)
    func presentSceneDidUpdateSync(response: Event.SceneDidUpdateSync.Response)
    func presentDidTapCreateAccountButtonSync(response: Event.DidTapCreateAccountButtonSync.Response)
}

extension SignUpScene {
    
    public typealias PresentationLogic = SignUpScenePresentationLogic
    
    @objc(SignUpScenePresenter)
    public class Presenter: NSObject {
        
        public typealias Event = SignUpScene.Event
        public typealias Model = SignUpScene.Model
        
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

private extension SignUpScene.Presenter {
    
    func mapSceneModel(_ sceneModel: Model.SceneModel) -> Model.SceneViewModel {
        
        let networkError: String?
        let emailError: String?
        let passwordError: String?
        let passwordConfirmationError: String?
        
        switch sceneModel.networkError {
        case .emptyString:
            networkError = Localized(.validation_error_empty)
        case .none:
            networkError = nil
        }
        
        switch sceneModel.emailError {
        
        case .none:
            emailError = nil
            
        case .emptyString:
            emailError = Localized(.validation_error_empty)
            
        case .emailDoesNotMatchRequirements:
            emailError = Localized(.sign_up_email_validation_error)
        }
        
        switch sceneModel.passwordError {
        
        case .none:
            passwordError = nil
            
        case .emptyString:
            passwordError = Localized(.validation_error_empty)
            
        case .passwordDoesNotMatchRequirements:
            passwordError = Localized(.sign_up_password_validation_error)
        }
        
        switch sceneModel.passwordConfirmationError {
        
        case .none:
            passwordConfirmationError = nil
            
        case .emptyString:
            passwordConfirmationError = Localized(.validation_error_empty)
            
        case .passwordsDoNotMatch:
            passwordConfirmationError = Localized(.sign_up_password_confirmation_validation_error)
        }
        
        return .init(
            network: sceneModel.network,
            email: sceneModel.email,
            password: sceneModel.password,
            passwordConfirmation: sceneModel.passwordConfirmation,
            networkError: networkError,
            emailError: emailError,
            passwordError: passwordError,
            passwordConfirmationError: passwordConfirmationError
        )
    }
}

// MARK: - PresenterLogic

extension SignUpScene.Presenter: SignUpScene.PresentationLogic {
    
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
    
    public func presentDidTapCreateAccountButtonSync(response: Event.DidTapCreateAccountButtonSync.Response) {
        let viewModel: Event.DidTapCreateAccountButtonSync.ViewModel = response
        self.presenterDispatch.displaySync { (displayLogic) in
            displayLogic.displayDidTapCreateAccountButtonSync(viewModel: viewModel)
        }
    }
}
