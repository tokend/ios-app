import Foundation

public protocol ChangePasswordScenePresentationLogic {
    
    typealias Event = ChangePasswordScene.Event
    
    func presentSceneDidUpdate(response: Event.SceneDidUpdate.Response)
    func presentSceneDidUpdateSync(response: Event.SceneDidUpdateSync.Response)
    func presentDidTapChangeButtonSync(response: Event.DidTapChangeButtonSync.Response)
}

extension ChangePasswordScene {
    
    public typealias PresentationLogic = ChangePasswordScenePresentationLogic
    
    @objc(ChangePasswordScenePresenter)
    public class Presenter: NSObject {
        
        public typealias Event = ChangePasswordScene.Event
        public typealias Model = ChangePasswordScene.Model
        
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

private extension ChangePasswordScene.Presenter {
    
    func mapSceneModel(_ sceneModel: Model.SceneModel) -> Model.SceneViewModel {
        
        let currentPasswordError: String?
        let newPasswordError: String?
        let confirmPasswordError: String?
        
        switch sceneModel.currentPasswordError {
        case .emptyString:
            currentPasswordError = Localized(.validation_error_empty)
        case .none:
            currentPasswordError = nil
        }
        
        switch sceneModel.newPasswordError {
        case .emptyString:
            newPasswordError = Localized(.validation_error_empty)
        case .none:
            newPasswordError = nil
        }
        
        switch sceneModel.confirmPasswordError {
        case .emptyString:
            confirmPasswordError = Localized(.validation_error_empty)
        case .passwordsDoNotMatch:
            confirmPasswordError = Localized(.change_password_passwords_do_not_match)
        case .none:
            confirmPasswordError = nil
        }
        
        return .init(
            currentPassword: sceneModel.currentPassword,
            currentPasswordError: currentPasswordError,
            newPassword: sceneModel.newPassword,
            newPasswordError: newPasswordError,
            confirmPassword: sceneModel.confirmPassword,
            confirmPasswordError: confirmPasswordError
        )
    }
}

// MARK: - PresenterLogic

extension ChangePasswordScene.Presenter: ChangePasswordScene.PresentationLogic {
    
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
    
    public func presentDidTapChangeButtonSync(response: Event.DidTapChangeButtonSync.Response) {
        let viewModel: Event.DidTapChangeButtonSync.ViewModel = response
        self.presenterDispatch.displaySync { (displayLogic) in
            displayLogic.displayDidTapChangeButtonSync(viewModel: viewModel)
        }
    }
}
