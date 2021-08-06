import Foundation
import RxSwift
import TokenDSDK

public protocol SettingsSceneBusinessLogic {
    
    typealias Event = SettingsScene.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request)
    func onDidTapItemSync(request: Event.DidTapItemSync.Request)
    func onSwitcherValueDidChange(request: Event.SwitcherValueDidChange.Request)
    func onDidRefresh(request: Event.DidRefresh.Request)
}

extension SettingsScene {
    
    public typealias BusinessLogic = SettingsSceneBusinessLogic
    
    @objc(SettingsSceneInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = SettingsScene.Event
        public typealias Model = SettingsScene.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private var sceneModel: Model.SceneModel
        private let biometricsInfoProvider: BiometricsInfoProviderProtocol
        private let tfaManager: TFAManagerProtocol
        private let settingsManager: SettingsManagerProtocol
        
        private let disposeBag: DisposeBag = .init()
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic,
            biometricsInfoProvider: BiometricsInfoProviderProtocol,
            tfaManager: TFAManagerProtocol,
            settingsManager: SettingsManagerProtocol
        ) {
            
            self.presenter = presenter
            self.biometricsInfoProvider = biometricsInfoProvider
            self.tfaManager = tfaManager
            self.settingsManager = settingsManager
            
            self.sceneModel = .init(
                loadingStatus: .loaded,
                sections: [
                    .init(
                        id: "AppSection",
                        items: [.language]
                    ),
                    .init(
                        id: "AccountSection",
                        items: [
                            .accountId,
                            .verification,
                            .secretSeed,
                            .signOut
                        ]
                    ),
                    .init(
                        id: "SecuritySection",
                        items: [
                            .lockApp,
                            .biometrics,
                            .tfa,
                            .changePassword
                        ]
                    )
                ],
                // TODO: - Add localization
                preferredLanguage: "English",
                lockAppIsEnabled: false,
                biometricsType: biometricsInfoProvider.biometricsType,
                biometricsIsEnabled: settingsManager.biometricsAuthEnabled,
                tfaStatus: tfaManager.state
            )
        }
    }
}

// MARK: - Private methods

private extension SettingsScene.Interactor {
    
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
    
    func observeTFA() {
        tfaManager
            .observeTfaState()
            .subscribe(onNext: { [weak self] (state) in
                self?.sceneModel.tfaStatus = state
                self?.presentSceneDidUpdate(animated: true)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - BusinessLogic

extension SettingsScene.Interactor: SettingsScene.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        observeTFA()
    }
    
    public func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request) {
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidTapItemSync(request: Event.DidTapItemSync.Request) {
        
        guard let item = Model.Item(rawValue: request.id)
        else {
            return
        }
        
        let response: Event.DidTapItemSync.Response = .init(item: item)
        presenter.presentDidTapItemSync(response: response)
    }
    
    public func onSwitcherValueDidChange(request: Event.SwitcherValueDidChange.Request) {
        
        guard let item = Model.Item(rawValue: request.id)
        else {
            return
        }
        
        switch item {
        
        case .language,
             .accountId,
             .verification,
             .secretSeed,
             .signOut,
             .changePassword:
            return
            
        case .lockApp:
            // TODO: - Implement
            break
            
        case .biometrics:
            settingsManager.biometricsAuthEnabled = request.newValue
            sceneModel.biometricsIsEnabled = settingsManager.biometricsAuthEnabled
            presentSceneDidUpdateSync(animated: true)
            
        case .tfa:
            let completion: (Result<Void, Swift.Error>) -> Void = { (result) in
                
                switch result {
                
                case .success:
                    break
                    
                case .failure(error: let error):
                    
                    if case TFAApi.CreateFactorError.tfaCancelled = error {
                        return
                    }
                    
                    if case TFAApi.UpdateFactorError.tfaCancelled = error {
                        return
                    }
                    
                    if case TFAApi.DeleteFactorError.tfaCancelled = error {
                        return
                    }
                    
                    let response: Event.ErrorOccured.Response = .init(error: error)
                    self.presenter.presentErrorOccured(response: response)
                }
            }
            
            if request.newValue {
                tfaManager.enableTFA(completion: completion)
            } else {
                tfaManager.disableTFA(completion: completion)
            }
        }
    }
    
    public func onDidRefresh(request: Event.DidRefresh.Request) { }
}
