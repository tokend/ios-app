import Foundation
import TokenDSDK
import TokenDWallet

class SettingsFlowController: BaseSignedInFlowController {

    // MARK: - Private properties

    private lazy var rootViewController: SettingsScene.ViewController = initSettings()

    private let navigationController: NavigationControllerProtocol
    private let onAskSignOut: () -> Void
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
        onBackAction: @escaping () -> Void
    ) {

        self.navigationController = navigationController
        self.onAskSignOut = onAskSignOut
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
    
    override func handleTFASecret(_ secret: String, seed: String, completion: @escaping (Bool) -> Void) {
        
        if let currentFlowController = currentFlowController {
            currentFlowController.handleTFASecret(secret, seed: seed, completion: completion)
        } else {
            let alert = self.setupTFASecretAlert(secret, seed: seed, completion: completion)
            self.navigationController.present(alert, animated: true, completion: nil)
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
            onLanguageTap: {
                // TODO: - Implement
            },
            onAccountIdTap: { [weak self] in
                self?.showAccountId()
            },
            onVerificationTap: { [weak self] in
                                
                guard let string = self?.flowControllerStack.apiConfigurationModel.verificationUrl,
                      let link = URL(string: string),
                      UIApplication.shared.canOpenURL(link)
                else {
                    return
                }
                
                UIApplication.shared.open(link, options: [:], completionHandler: nil)
            },
            onSecretSeedTap: { [weak self] in
                self?.showSecretSeedConfirmation()
            },
            onSignOutTap: { [weak self] in
                self?.onAskSignOut()
            },
            onChangePasswordTap: { [weak self] in
                self?.showChangePassword()
            },
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
        
        let biometricsInfoProvider: SettingsScene.BiometricsInfoProviderProtocol = SettingsScene.BiometricsInfoProvider(
            biometricsInfoProvider: BiometricsInfoProvider()
        )
        
        let tfaManager: SettingsScene.TFAManagerProtocol = SettingsScene.TFAManager(
            tfaManager: managersController.tfaManager
        )
        
        let settingsManager: SettingsScene.SettingsManagerProtocol = SettingsScene.SettingsManager(
            settingsManager: managersController.settingsManager
        )

        SettingsScene.Configurator.configure(
            viewController: vc,
            routing: routing,
            biometricsInfoProvider: biometricsInfoProvider,
            tfaManager: tfaManager,
            settingsManager: settingsManager
        )

        return vc
    }
    
    func showSecretSeedConfirmation() {
        
        let alert: UIAlertController = .init(
            title: Localized(.secret_seed_confirmation_title),
            message: Localized(.secret_seed_confirmation_message),
            preferredStyle: .alert
        )
        
        alert.addAction(
            .init(
                title: Localized(.no),
                style: .cancel,
                handler: nil
            )
        )
        
        alert.addAction(
            .init(
                title: Localized(.yes),
                style: .destructive,
                handler: { [weak self] (_) in
                    self?.showSecretSeed()
                }
            )
        )
        
        navigationController.present(
            alert,
            animated: true,
            completion: nil
        )
    }
    
    func showSecretSeed() {
        
        let seedData = self.keychainDataProvider.getKeyData()
        let seed = Base32Check.encode(
            version: .seedEd25519,
            data: seedData.getSeedData()
        )
        
        let alert: UIAlertController = .init(
            title: Localized(.secret_seed_title),
            message: seed,
            preferredStyle: .alert
        )
        
        alert.addAction(
            .init(
                title: Localized(.copy),
                style: .default,
                handler: { (_) in
                    UIPasteboard.general.string = seed
                }
            )
        )
        
        alert.addAction(
            .init(
                title: Localized(.ok_alert_action),
                style: .cancel,
                handler: nil
            )
        )
        
        navigationController.present(
            alert,
            animated: true,
            completion: nil
        )
    }
    
    func showChangePassword() {
        
        let currentViewController: UIViewController? = navigationController.topViewController
        let flow: ChangePasswordFlowController = .init(
            appController: appController,
            flowControllerStack: flowControllerStack,
            reposController: reposController,
            managersController: managersController,
            userDataProvider: userDataProvider,
            keychainDataProvider: keychainDataProvider,
            rootNavigation: rootNavigation,
            onBack: { [weak self] in
                if let current = currentViewController {
                    self?.navigationController.popToViewController(current, animated: true)
                } else {
                    self?.navigationController.popViewController(true)
                }
                self?.currentFlowController = nil
            },
            onDidChangePassword: { [weak self] in
                if let current = currentViewController {
                    self?.navigationController.popToViewController(current, animated: true)
                } else {
                    self?.navigationController.popViewController(true)
                }
                self?.currentFlowController = nil
            },
            navigationController: navigationController
        )
        
        currentFlowController = flow
        flow.run({ (controller) in
            navigationController.pushViewController(controller, animated: true)
        })
    }
    
    func showAccountId() {
        
        navigationController.pushViewController(
            initAccountId(
                onBack: { [weak self] in
                    self?.navigationController.popViewController(true)
                }
            ),
            animated: true
        )
    }
    
    func initAccountId(
        onBack: @escaping () -> Void
    ) -> UIViewController {
        
        let viewController: QRCodeScene.ViewController = .init()
        viewController.hidesBottomBarWhenPushed = true
        
        let routing: QRCodeScene.Routing = .init(
            onBackAction: onBack,
            onShare: { [weak self] (valueToShare) in
                self?.shareValue(
                    valueToShare,
                    on: viewController
                )
            }
        )
        
        let accountIdProvider: QRCodeScene.AccountIDDataProvider = .init(
            userDataProvider: userDataProvider
        )
        
        QRCodeScene.Configurator.configure(
            viewController: viewController,
            routing: routing,
            dataProvider: accountIdProvider
        )
        
        return viewController
    }
    
    func shareValue(
        _ value: String,
        on viewController: UIViewController
    ) {
        
        let activity: UIActivityViewController = .init(
            activityItems: [value],
            applicationActivities: nil
        )
        
        viewController.present(
            activity,
            animated: true,
            completion: nil
        )
    }
}
