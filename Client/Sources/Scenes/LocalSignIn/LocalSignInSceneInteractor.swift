import Foundation
import RxSwift
import RxCocoa

public protocol LocalSignInSceneBusinessLogic {
    
    typealias Event = LocalSignInScene.Event
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request)
    func onDidEnterPasswordSync(request: Event.DidEnterPasswordSync.Request)
    func onDidTapBiometricsSync(request: Event.DidTapBiometricsSync.Request)
    func onDidTapLoginButtonSync(request: Event.DidTapLoginButtonSync.Request)
}

extension LocalSignInScene {
    
    public typealias BusinessLogic = LocalSignInSceneBusinessLogic
    
    @objc(LocalSignInSceneInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = LocalSignInScene.Event
        public typealias Model = LocalSignInScene.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private var sceneModel: Model.SceneModel
        private let userAvatarUrlProvider: UserAvatarUrlProviderProtocol
        private let biometricsInfoProvider: BiometricsInfoProviderProtocol
        
        private let disposeBag: DisposeBag = .init()
        
        // MARK: -
        
        public init(
            login: String,
            presenter: PresentationLogic,
            userAvatarUrlProvider: UserAvatarUrlProviderProtocol,
            biometricsInfoProvider: BiometricsInfoProviderProtocol
        ) {
            
            self.presenter = presenter
            self.userAvatarUrlProvider = userAvatarUrlProvider
            self.biometricsInfoProvider = biometricsInfoProvider
            
            let biometricsType: Model.BiometricsType
            
            switch biometricsInfoProvider.biometricsType {
            
            case .faceId:
                biometricsType = .faceId
                
            case .touchId:
                biometricsType = .touchId
                
            case .none:
                biometricsType = .none
            }
            
            self.sceneModel = .init(
                avatarUrl: nil,
                login: login,
                password: nil,
                passwordError: nil,
                biometricsType: biometricsType
            )
        }
    }
}

// MARK: - Private methods

private extension LocalSignInScene.Interactor {
    
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
    
    func validatePassword() -> Model.PasswordError? {
        
        guard let password = sceneModel.password,
              !password.isEmpty
        else {
            return .empty
        }
        
        return nil
    }
    
    func isAbleToLogin() -> Bool {
        sceneModel.passwordError = validatePassword()
        
        return sceneModel.passwordError == nil
    }
    
    func observeAvatarUrl() {
        userAvatarUrlProvider
            .observeAvatarUrl()
            .subscribe(onNext: { [weak self] (value) in
                self?.sceneModel.avatarUrl = value
                self?.presentSceneDidUpdate(animated: false)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - BusinessLogic

extension LocalSignInScene.Interactor: LocalSignInScene.BusinessLogic {
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        observeAvatarUrl()
    }
    
    public func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request) {
        presentSceneDidUpdateSync(animated: false)
        // FIXME: -
        let response: Event.DidTapBiometricsSync.Response = .init()
        presenter.presentDidTapBiometricsSync(response: response)
    }
    
    public func onDidEnterPasswordSync(request: Event.DidEnterPasswordSync.Request) {
        sceneModel.password = request.value
        sceneModel.passwordError = nil
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidTapBiometricsSync(request: Event.DidTapBiometricsSync.Request) {
        let response: Event.DidTapBiometricsSync.Response = .init()
        presenter.presentDidTapBiometricsSync(response: response)
    }
    
    public func onDidTapLoginButtonSync(request: Event.DidTapLoginButtonSync.Request) {
        
        guard isAbleToLogin(),
              let password = sceneModel.password
        else {
            presentSceneDidUpdateSync(animated: false)
            return
        }
        
        let response: Event.DidTapLoginButtonSync.Response = .init(password: password)
        presenter.presentDidTapLoginButtonSync(response: response)
    }
}
