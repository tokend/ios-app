import Foundation

public protocol ChangePasswordSceneBusinessLogic {
    
    typealias Event = ChangePasswordScene.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request)
    func onDidEnterCurrentPasswordSync(request: Event.DidEnterCurrentPasswordSync.Request)
    func onDidEnterNewPasswordSync(request: Event.DidEnterNewPasswordSync.Request)
    func onDidEnterConfirmPasswordSync(request: Event.DidEnterConfirmPasswordSync.Request)
    func onDidTapChangeButtonSync(request: Event.DidTapChangeButtonSync.Request)
}

extension ChangePasswordScene {
    
    public typealias BusinessLogic = ChangePasswordSceneBusinessLogic
    
    @objc(ChangePasswordSceneInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = ChangePasswordScene.Event
        public typealias Model = ChangePasswordScene.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private var sceneModel: Model.SceneModel
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic
        ) {
            
            self.presenter = presenter
            self.sceneModel = .init()
        }
    }
}

// MARK: - Private methods

private extension ChangePasswordScene.Interactor {
    
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
    
    func validateCurrentPassword() -> Model.CurrentPasswordValidationError? {
        guard sceneModel.currentPassword?.isEmpty == false
        else {
            return .emptyString
        }
        
        return nil
    }
    
    func validateNewPassword() -> Model.NewPasswordValidationError? {
        
        guard sceneModel.newPassword?.isEmpty == false
        else {
            return .emptyString
        }
        
        return nil
    }
    
    func validateConfirmPassword() -> Model.ConfirmPasswordValidationError? {
        guard sceneModel.confirmPassword?.isEmpty == false
        else {
            return .emptyString
        }
        
        guard sceneModel.newPassword == sceneModel.confirmPassword
        else {
            return .passwordsDoNotMatch
        }
        
        return nil
    }
    
    func isAbleToChange() -> Bool {
        sceneModel.currentPasswordError = validateCurrentPassword()
        sceneModel.newPasswordError = validateNewPassword()
        sceneModel.confirmPasswordError = validateConfirmPassword()
        
        return sceneModel.currentPasswordError == nil
            && sceneModel.newPasswordError == nil
            && sceneModel.confirmPasswordError == nil
    }
}

// MARK: - BusinessLogic

extension ChangePasswordScene.Interactor: ChangePasswordScene.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) { }
    
    public func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request) { }
    
    public func onDidEnterCurrentPasswordSync(request: Event.DidEnterCurrentPasswordSync.Request) {
        sceneModel.currentPassword = request.value
        sceneModel.currentPasswordError = nil
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidEnterNewPasswordSync(request: Event.DidEnterNewPasswordSync.Request) {
        sceneModel.newPassword = request.value
        sceneModel.newPasswordError = nil
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidEnterConfirmPasswordSync(request: Event.DidEnterConfirmPasswordSync.Request) {
        sceneModel.confirmPassword = request.value
        sceneModel.confirmPasswordError = nil
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidTapChangeButtonSync(request: Event.DidTapChangeButtonSync.Request) {
        
        guard isAbleToChange(),
              let currentPassword = sceneModel.currentPassword,
              let newPassword = sceneModel.newPassword
        else {
            presentSceneDidUpdateSync(animated: false)
            return
        }

        let response: Event.DidTapChangeButtonSync.Response = .init(
            currentPassword: currentPassword,
            newPassword: newPassword
        )
        presenter.presentDidTapChangeButtonSync(response: response)
    }
}
