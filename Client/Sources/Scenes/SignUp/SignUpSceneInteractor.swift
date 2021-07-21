import Foundation
import RxCocoa
import RxSwift

public protocol SignUpSceneBusinessLogic {
    
    typealias Event = SignUpScene.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request)
    func onDidEnterEmailSync(request: Event.DidEnterEmailSync.Request)
    func onDidEnterPasswordSync(request: Event.DidEnterPasswordSync.Request)
    func onDidEnterPasswordConfirmationSync(request: Event.DidEnterPasswordConfirmationSync.Request)
    func onDidTapCreateAccountButtonSync(request: Event.DidTapCreateAccountButtonSync.Request)
}

extension SignUpScene {
    
    public typealias BusinessLogic = SignUpSceneBusinessLogic
    
    @objc(SignUpSceneInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = SignUpScene.Event
        public typealias Model = SignUpScene.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private var sceneModel: Model.SceneModel
        private let networkInfoProvider: NetworkInfoProviderProtocol
        
        private let disposeBag: DisposeBag = .init()

        // MARK: -
        
        public init(
            presenter: PresentationLogic,
            networkInfoProvider: NetworkInfoProviderProtocol
        ) {
            
            self.presenter = presenter
            self.networkInfoProvider = networkInfoProvider

            self.sceneModel = .init()
        }
    }
}

// MARK: - Private methods

private extension SignUpScene.Interactor {
    
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
    
    func validateNetwork() -> Model.NetworkValidationError? {
        guard let network = sceneModel.network,
              !network.isEmpty
        else {
            return .emptyString
        }
        
        return nil
    }
    
    func validateEmail() -> Model.EmailValidationError? {
        
        guard let email = sceneModel.email
        else {
            return .emptyString
        }
        
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .emptyString
        }
        
        return email.validateEmail()
            ? nil
            : .emailDoesNotMatchRequirements
    }
    
    func validatePassword() -> Model.PasswordValidationError? {
        
        guard let password = sceneModel.password
        else {
            return .emptyString
        }
        
        return validatePassword(password: password)
            ? nil
            : .passwordDoesNotMatchRequirements
    }
    
    func validatePassword(password: String) -> Bool {
        return password.count > 5
    }
    
    func validatePasswordConfirmation() -> Model.PasswordConfirmationError? {
        
        guard let passwordConfirmation = sceneModel.passwordConfirmation
        else {
            return .emptyString
        }
        
        return sceneModel.password == passwordConfirmation
            ? nil
            : .passwordsDoNotMatch
    }
    
    func isAbleToContinue() -> Bool {
        
        sceneModel.networkError = validateNetwork()
        sceneModel.emailError = validateEmail()
        sceneModel.passwordError = validatePassword()
        sceneModel.passwordConfirmationError = validatePasswordConfirmation()
        
        return sceneModel.networkError == nil
            && sceneModel.emailError == nil
            && sceneModel.passwordError == nil
            && sceneModel.passwordConfirmationError == nil
    }
    
    func observeNetworkInfo() {
        networkInfoProvider
            .observeNetwork()
            .subscribe(onNext: { [weak self] (value) in
                self?.sceneModel.network = value
                self?.presentSceneDidUpdate(animated: false)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - BusinessLogic

extension SignUpScene.Interactor: SignUpScene.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        observeNetworkInfo()
    }
    
    public func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request) {
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidEnterEmailSync(request: Event.DidEnterEmailSync.Request) {
        sceneModel.email = request.value
        sceneModel.emailError = nil
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidEnterPasswordSync(request: Event.DidEnterPasswordSync.Request) {
        sceneModel.password = request.value
        sceneModel.passwordError = nil
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidEnterPasswordConfirmationSync(request: Event.DidEnterPasswordConfirmationSync.Request) {
        sceneModel.passwordConfirmation = request.value
        sceneModel.passwordConfirmationError = nil
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidTapCreateAccountButtonSync(request: Event.DidTapCreateAccountButtonSync.Request) {
        
        guard let email = sceneModel.email,
              let password = sceneModel.password,
              isAbleToContinue()
        else {
            presentSceneDidUpdateSync(animated: false)
            return
        }
        
        let response: Event.DidTapCreateAccountButtonSync.Response = .init(
            email: email,
            password: password
        )
        presenter.presentDidTapCreateAccountButtonSync(response: response)
    }
}
