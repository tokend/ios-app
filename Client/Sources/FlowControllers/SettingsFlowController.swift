import Foundation
import TokenDSDK

class SettingsFlowController: BaseSignedInFlowController {

    // MARK: - Private properties

    private lazy var rootViewController: SettingsScene.ViewController = initSettings()

    private let navigationController: NavigationControllerProtocol
    private let onAskSignOut: () -> Void
    private let onPerformSignOut: () -> Void
    private let onBackAction: () -> Void
    
    // MARK: -

    init(
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        reposController: ReposController,
        managersController: ManagersController,
        userDataProvider: UserDataProviderProtocol,
        keychainDataProvider: KeychainDataProviderProtocol,
        rootNavigation: RootNavigationProtocol,
        navigationController: NavigationControllerProtocol,
        onAskSignOut: @escaping () -> Void,
        onPerformSignOut: @escaping () -> Void,
        onBackAction: @escaping () -> Void
    ) {

        self.navigationController = navigationController
        self.onAskSignOut = onAskSignOut
        self.onPerformSignOut = onPerformSignOut
        self.onBackAction = onBackAction
        
        super.init(
            appController: appController,
            flowControllerStack: flowControllerStack,
            reposController: reposController,
            managersController: managersController,
            userDataProvider: userDataProvider,
            keychainDataProvider: keychainDataProvider,
            rootNavigation: rootNavigation
        )
    }

    // MARK: - Public

    public func run(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        showRootScreen?(rootViewController)
        rootViewController.navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func performTFA(tfaInput: ApiCallbacks.TFAInput, cancel: @escaping () -> Void) {
        
        if let currentFlowController = currentFlowController {
            currentFlowController.performTFA(tfaInput: tfaInput, cancel: cancel)
        } else {
            navigationController.hideProgress()
            
            let viewController = self.setupTFA(
                tfaInput: tfaInput,
                onDone: { [weak self] in
                    self?.navigationController.showProgress()
                },
                onClose: { [weak self] in
                    
                    self?.navigationController.hideProgress()
                    
                    switch tfaInput {
                    
                    case .password(_, _):
                        break
                        
                    case .code(_, _):
                        self?.navigationController.popViewController(true)
                    }
                },
                cancel: cancel
            )
            
            switch tfaInput {
            
            case .password(_, _):
                self.navigationController.present(
                    viewController,
                    animated: true,
                    completion: nil
                )
                
            case .code(_, _):
                self.navigationController.present(
                    viewController,
                    animated: true,
                    completion: nil
                )
            }
        }
    }
}

// MARK: - Private methods

private extension SettingsFlowController {

    func initSettings(
    ) -> SettingsScene.ViewController {

        let vc: SettingsScene.ViewController = .init()

        let routing: SettingsScene.Routing = .init(
            onBackAction: { [weak self] in
                self?.onBackAction()
            },
            onLanguageTap: { [weak self] in },
            onAccountIdTap: { [weak self] in },
            onVerificationTap: { [weak self] in },
            onSecretSeedTap: { [weak self] in },
            onSignOutTap: { [weak self] in
                self?.onAskSignOut()
            },
            onChangePasswordTap: { [weak self] in },
            onShowError: { [weak self] (error) in
                if case TFAApi.UpdateFactorError.tfaFailed = error {
                    self?.navigationController.showErrorMessage(Localized(.settings_tfa_wrong_code_error), completion: nil)
                } else {
                    self?.navigationController.showErrorMessage(
                        Localized(.error_unknown),
                        completion: nil
                    )
                }
            }
        )

        let biometricsInfoProvider: BiometricsInfoProviderProtocol = BiometricsInfoProvider()

        SettingsScene.Configurator.configure(
            viewController: vc,
            routing: routing,
            biometricsInfoProvider: biometricsInfoProvider,
            tfaManager: managersController.tfaManager,
            settingsManager: managersController.settingsManager
        )

        return vc
    }
}
