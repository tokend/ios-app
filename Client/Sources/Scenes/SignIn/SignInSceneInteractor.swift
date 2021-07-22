import Foundation
import RxCocoa
import RxSwift

public protocol SignInSceneBusinessLogic {
    
    typealias Event = SignInScene.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request)
    func onDidEnterLoginSync(request: Event.DidEnterLoginSync.Request)
    func onDidEnterPasswordSync(request: Event.DidEnterPasswordSync.Request)
    func onDidTapLoginButtonSync(request: Event.DidTapLoginButtonSync.Request)
}

extension SignInScene {
    
    public typealias BusinessLogic = SignInSceneBusinessLogic
    
    @objc(SignInSceneInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = SignInScene.Event
        public typealias Model = SignInScene.Model
        
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
            
            self.sceneModel = .init(
                network: networkInfoProvider.network,
                login: nil,
                password: nil,
                networkError: nil,
                loginError: nil,
                passwordError: nil
            )
        }
    }
}

// MARK: - Private methods

private extension SignInScene.Interactor {
    
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
    
    func validateLogin() -> Model.LoginValidationError? {
        
        guard let login = sceneModel.login
        else {
            return .emptyString
        }
        
        return login.validateEmail()
            ? nil
            : .doesNotMatchRequirements
    }
    
    func validatePassword() -> Model.PasswordValidationError? {
        guard let login = sceneModel.login
        else {
            return .emptyString
        }
        
        return login.count > 6
            ? nil
            : .doesNotMatchRequirements
    }
    
    func isAbleToLogin() -> Bool {
        sceneModel.networkError = validateNetwork()
        sceneModel.loginError = validateLogin()
        sceneModel.passwordError = validatePassword()
        
        return sceneModel.networkError == nil
            && sceneModel.loginError == nil
            && sceneModel.passwordError == nil
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

extension SignInScene.Interactor: SignInScene.BusinessLogic {
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        observeNetworkInfo()
    }
    
    public func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request) {
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidEnterLoginSync(request: Event.DidEnterLoginSync.Request) {
        sceneModel.login = request.value
        sceneModel.loginError = nil
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidEnterPasswordSync(request: Event.DidEnterPasswordSync.Request) {
        sceneModel.password = request.value
        sceneModel.passwordError = nil
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidTapLoginButtonSync(request: Event.DidTapLoginButtonSync.Request) {
        
        guard isAbleToLogin(),
              let login = sceneModel.login,
              let password = sceneModel.password
        else {
            presentSceneDidUpdateSync(animated: false)
            return
        }

        let response: Event.DidTapLoginButtonSync.Response = .init(
            login: login,
            password: password
        )
        presenter.presentDidTapLoginButtonSync(response: response)
    }
}
