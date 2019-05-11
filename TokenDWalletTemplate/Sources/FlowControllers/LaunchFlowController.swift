import UIKit
import TokenDSDK
import QRCodeReader

class LaunchFlowController: BaseFlowController {
    
    // MARK: - Private properties
    
    private let navigationController: NavigationControllerProtocol = NavigationController()
    private var userDataManager: UserDataManagerProtocol
    private var keychainManager: KeychainManagerProtocol
    private let onAuthorized: (_ account: String) -> Void
    private let onSignOut: () -> Void
    
    private var submittedEmail: String?
    
    // MARK: -
    
    init(
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        rootNavigation: RootNavigationProtocol,
        userDataManager: UserDataManagerProtocol,
        keychainManager: KeychainManagerProtocol,
        onAuthorized: @escaping (_ account: String) -> Void,
        onSignOut: @escaping  () -> Void
        ) {
        
        self.userDataManager = userDataManager
        self.keychainManager = keychainManager
        self.onAuthorized = onAuthorized
        self.onSignOut = onSignOut
        
        super.init(
            appController: appController,
            flowControllerStack: flowControllerStack,
            rootNavigation: rootNavigation
        )
    }
    
    // MARK: - Overridden
    
    override func showBlockingProgress() {
        self.navigationController.showProgress()
    }
    
    override func hideBlockingProgress() {
        self.navigationController.hideProgress()
    }
    
    // MARK: - Public
    
    class func canHandle(
        launchOptions: [UIApplication.LaunchOptionsKey: Any],
        userDataManager: UserDataManagerProtocol
        ) -> URL? {
        
        let key = UIApplication.LaunchOptionsKey.userActivityDictionary
        if let userActivityInfo = launchOptions[key] as? [String: Any],
            let activity = userActivityInfo["UIApplicationLaunchOptionsUserActivityKey"] as? NSUserActivity {
            
            if activity.activityType == NSUserActivityTypeBrowsingWeb, let url = activity.webpageURL {
                if self.canHandle(url: url, userDataManager: userDataManager) {
                    return url
                }
            }
        }
        
        return nil
    }
    
    class func canHandle(
        url: URL,
        userDataManager: UserDataManagerProtocol
        ) -> Bool {
        
        let hasToken = VerifyEmailWorker.canHandle(url: url)
        let hasWalletId = VerifyEmailWorker.checkSavedWalletData(userDataManager: userDataManager) != nil
        
        return hasToken && hasWalletId
    }
    
    func start() {
        var launchUrl: URL?
        if let launchOptions = self.appController.getLaunchOptions() {
            launchUrl = LaunchFlowController.canHandle(
                launchOptions: launchOptions,
                userDataManager: self.userDataManager
            )
        }
        
        if let mainAccount = self.userDataManager.getMainAccount(),
            self.userDataManager.hasWalletDataForMainAccount(),
            !self.userDataManager.isSignedViaAuthenticator() {
            
            self.runLocalAuthFlow(account: mainAccount, fromBackground: false)
        } else if
            let walletData = VerifyEmailWorker.checkSavedWalletData(userDataManager: self.userDataManager),
            let launchUrl = launchUrl {
            
            let registerScreen = self.setupRegisterScreen()
            let verifyEmailScreen = self.setupVerifyEmailScreen(
                walletId: walletData.walletId,
                launchOptionsUrl: launchUrl
            )
            
            self.startFrom(vcs: [registerScreen, verifyEmailScreen], animated: true)
        } else {
            let vc = self.setupRegisterScreen()
            
            self.startFrom(vcs: [vc], animated: true)
        }
    }
    
    // MARK: - Private
    
    private func runLocalAuthFlow(account: String, fromBackground: Bool) {
        let flow = LocalAuthFlowController(
            account: account,
            appController: self.appController,
            flowControllerStack: self.flowControllerStack,
            rootNavigation: self.rootNavigation,
            userDataManager: self.userDataManager,
            keychainManager: self.keychainManager,
            onAuthorized: { [weak self] in
                self?.onAuthorized(account)
            },
            onRecoverySucceeded: { [weak self] in
                self?.showRegisterScreenFromLocalAuth()
            },
            onSignOut: { [weak self] in
                self?.onSignOut()
        })
        self.currentFlowController = flow
        flow.run(showRootScreen: nil)
    }
    
    private func showRegisterScreenFromLocalAuth() {
        let vc = self.setupRegisterScreen()
        
        self.startFrom(vcs: [vc], animated: true)
    }
    
    private func startFrom(vcs: [UIViewController], animated: Bool) {
        self.navigationController.setViewControllers(vcs, animated: false)
        self.rootNavigation.setRootContent(self.navigationController, transition: .fade, animated: animated)
    }
    
    private func showRecoveryScreen() {
        let vc = self.setupRecoveryScreen(onSuccess: { [weak self] in
            guard let present = self?.navigationController.getPresentViewControllerClosure() else {
                return
            }
            self?.showSuccessMessage(
                title: Localized(.success),
                message: Localized(.account_has_been_successfully_recovered),
                completion: {
                    self?.navigationController.popViewController(true)
            },
                presentViewController: present
            )
        })
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func setupRecoveryScreen(onSuccess: @escaping () -> Void) -> UpdatePassword.ViewController {
        let vc = UpdatePassword.ViewController()
        
        let updateRequestBuilder = UpdatePasswordRequestBuilder(
            keyServerApi: self.flowControllerStack.keyServerApi
        )
        let passwordValidator = PasswordValidator()
        let submitPasswordHandler = UpdatePassword.RecoverWalletWorker(
            keyserverApi: self.flowControllerStack.keyServerApi,
            keychainManager: self.keychainManager,
            userDataManager: self.userDataManager,
            networkInfoFetcher: self.flowControllerStack.networkInfoFetcher,
            updateRequestBuilder: updateRequestBuilder,
            passwordValidator: passwordValidator
        )
        
        let fields = submitPasswordHandler.getExpectedFields()
        let sceneModel = UpdatePassword.Model.SceneModel(fields: fields)
        
        let routing = UpdatePassword.Routing(
            onShowProgress: { [weak self] in
                self?.navigationController.showProgress()
            },
            onHideProgress: { [weak self] in
                self?.navigationController.hideProgress()
            },
            onShowErrorMessage: { [weak self] (errorMessage) in
                self?.navigationController.showErrorMessage(errorMessage, completion: nil)
            },
            onSubmitSucceeded: {
                onSuccess()
        })
        
        UpdatePassword.Configurator.configure(
            viewController: vc,
            sceneModel: sceneModel,
            submitPasswordHandler: submitPasswordHandler,
            routing: routing
        )
        
        vc.navigationItem.title = Localized(.recovery)
        
        return vc
    }
    
    private func showVerifyEmailScreen(walletId: String) {
        let registerScreen = self.setupRegisterScreen()
        
        let verifyScreen = self.setupVerifyEmailScreen(
            walletId: walletId,
            launchOptionsUrl: nil
        )
        
        self.navigationController.setViewControllers([registerScreen, verifyScreen], animated: true)
    }
    
    private func setupVerifyEmailScreen(
        walletId: String,
        launchOptionsUrl: URL?
        ) -> VerifyEmail.ViewController {
        
        let vc = VerifyEmail.ViewController()
        
        let verifyEmailWorker = VerifyEmailWorker(
            keyServerApi: self.flowControllerStack.keyServerApi,
            userDataManager: self.userDataManager,
            walletId: walletId
        )
        
        let routing = VerifyEmail.Routing(
            showProgress: { [weak self] in
                self?.navigationController.showProgress()
            },
            hideProgress: { [weak self] in
                self?.navigationController.hideProgress()
            },
            showErrorMessage: { [weak self] (errorMessage) in
                self?.navigationController.showErrorMessage(errorMessage, completion: nil)
            },
            onEmailVerified: { [weak self] in
                self?.handleEmailVerified()
        })
        
        VerifyEmail.Configurator.configure(
            viewController: vc,
            appController: self.appController,
            resendWorker: verifyEmailWorker,
            verifyWorker: verifyEmailWorker,
            launchOptionsUrl: launchOptionsUrl,
            routing: routing
        )
        
        vc.navigationItem.title = Localized(.verify_email)
        
        return vc
    }
    
    private func handleEmailVerified() {
        if let mainAccount = self.userDataManager.getMainAccount(),
            self.keychainManager.hasKeyDataForMainAccount(),
            self.userDataManager.hasWalletDataForMainAccount() {
            
            self.runLocalAuthFlow(account: mainAccount, fromBackground: false)
        } else {
            self.showSignInScreenOnVerified()
        }
    }
    
    private func showRecoverySeedScreen(
        model: RegisterScene.TokenDRegisterWorker.SignUpModel
        ) {
        
        let vc = self.setupRecoverySeedScreen(model: model)
        
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func setupRecoverySeedScreen(
        model: RegisterScene.TokenDRegisterWorker.SignUpModel
        ) -> RecoverySeed.ViewController {
        
        let vc = RecoverySeed.ViewController()
        
        let signUpWorker = RecoverySeed.SignUpWorker(
            keyServerApi: self.flowControllerStack.keyServerApi,
            userDataManager: self.userDataManager,
            signUpModel: model
        )
        
        let routing = RecoverySeed.Routing(
            onShowMessage: { [weak self] message in
                guard let present = self?.navigationController.getPresentViewControllerClosure() else {
                    return
                }
                
                self?.showDialog(
                    title: message,
                    message: nil,
                    style: .alert,
                    options: [],
                    onSelected: { _ in },
                    onCanceled: nil,
                    presentViewController: present
                )
            },
            onRegisterFailure: { [weak self] (message) in
                self?.navigationController.showErrorMessage(
                    message,
                    completion: {
                        self?.navigationController.popViewController(true)
                })
            },
            onShowAlertDialog: { [weak self] (message, options, onSelected) in
                guard let present = self?.navigationController.getPresentViewControllerClosure() else {
                    return
                }
                
                self?.showDialog(
                    title: nil,
                    message: message,
                    style: .alert,
                    options: options,
                    onSelected: onSelected,
                    onCanceled: nil,
                    presentViewController: present
                )
            },
            onSuccessfulRegister: { [weak self] (account, walletData) in
                self?.handleSuccessfulRegister(account: account, walletData: walletData)
            }, showLoading: { [weak self] in
                self?.navigationController.showProgress()
            }, hideLoading: { [weak self] in
                self?.navigationController.hideProgress()
            })
        
        RecoverySeed.Configurator.configure(
            viewController: vc,
            signUpWorker: signUpWorker,
            seed: model.recoverySeed,
            routing: routing
        )
        
        vc.navigationItem.title = Localized(.recovery_seed)
        vc.navigationItem.hidesBackButton = true
        
        return vc
    }
    
    private func showSignInScreenOnVerified() {
        let vc = self.setupRegisterScreen()
        
        self.navigationController.setViewControllers([vc], animated: true)
    }
    
    private func setupRegisterScreen() -> RegisterScene.ViewController {
        let vc = RegisterScene.ViewController()
        
        let provider = TermsInfoProvider(apiConfigurationModel: self.flowControllerStack.apiConfigurationModel)
        let termsUrl = provider.getTermsUrl()
        let sceneModel = RegisterScene.Model.SceneModel.signInWithEmail(self.submittedEmail, termsUrl: termsUrl)
        let signUpRequestBuilder = SignUpRequestBuilder(
            keyServerApi: self.flowControllerStack.keyServerApi
        )
        
        let registrationWorker = RegisterScene.TokenDRegisterWorker(
            appController: self.appController,
            flowControllerStack: self.flowControllerStack,
            userDataManager: self.userDataManager,
            keychainManager: self.keychainManager,
            signUpRequestBuilder: signUpRequestBuilder,
            onSubmitEmail: { [weak self] (email) in
                self?.submittedEmail = email
            })
        
        let passwordValidator = PasswordValidator()
        
        let routing = RegisterScene.Routing(
            showProgress: { [weak self] in
                self?.navigationController.showProgress()
            },
            hideProgress: { [weak self] in
                self?.navigationController.hideProgress()
            },
            showErrorMessage: { [weak self] (errorMessage, completion) in
                self?.navigationController.showErrorMessage(errorMessage, completion: completion)
            },
            onSuccessfulLogin: { [weak self] (account) in
                self?.onAuthorized(account)
            },
            onUnverifiedEmail: { [weak self] (walletId) in
                self?.showVerifyEmailScreen(walletId: walletId)
            },
            onPresentQRCodeReader: { [weak self] (completion) in
                self?.presentQRCodeReader(completion: completion)
            },
            onShowRecoverySeed: { [weak self] (model) in
                self?.showRecoverySeedScreen(model: model)
            },
            onRecovery: { [weak self] in
                self?.showRecoveryScreen()
            },
            onAuthenticatorSignIn: { [weak self] in
                self?.runAuthenticatorAuthFlow()
            },
            showDialogAlert: { [weak self] (title, message, options, onSelected, onCanceled) in
                guard let present = self?.navigationController.getPresentViewControllerClosure() else {
                    return
                }
                
                self?.showDialog(
                    title: title,
                    message: message,
                    style: .alert,
                    options: options,
                    onSelected: onSelected,
                    onCanceled: onCanceled,
                    presentViewController: present
                )
            },
            onSignedOut: {},
            onShowTerms: { [weak self] (url) in
                self?.presentTermsScreen(url)
        })
        
        RegisterScene.Configurator.configure(
            viewController: vc,
            sceneModel: sceneModel,
            registerWorker: registrationWorker,
            passwordValidator: passwordValidator,
            routing: routing
        )
        
        vc.navigationItem.title = Localized(.tokend)
        
        return vc
    }
    
    private func handleSuccessfulRegister(
        account: String,
        walletData: RegisterScene.Model.WalletData
        ) {
        
        if walletData.verified {
            if self.keychainManager.hasKeyDataForMainAccount() {
                self.onAuthorized(account)
            } else {
                self.showSignInScreenOnVerified()
            }
        } else {
            self.showVerifyEmailScreen(walletId: walletData.walletId)
        }
    }
    
    private func runAuthenticatorAuthFlow() {
        self.keychainManager = AuthKeychainManager()
        self.appController.updateFlowControllerStack(
            self.flowControllerStack.apiConfigurationModel,
            self.keychainManager
        )
        
        let flowController = AuthenticatorAuthFlowController(
            appController: self.appController,
            flowControllerStack: self.flowControllerStack,
            rootNavigation: self.rootNavigation,
            navigationController: self.navigationController,
            userDataManager: self.userDataManager,
            keychainManager: self.keychainManager,
            onAuthorized: { [weak self] (account) in
                self?.onAuthorized(account)
            },
            onCancelled: { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.navigationController.popViewController(true)
                strongSelf.keychainManager = KeychainManager()
                strongSelf.appController.updateFlowControllerStack(
                    strongSelf.flowControllerStack.apiConfigurationModel,
                    strongSelf.keychainManager
                )
                strongSelf.currentFlowController = nil
        })
        
        flowController.run { [weak self] (vc) in
            self?.navigationController.pushViewController(vc, animated: true)
            self?.currentFlowController = flowController
        }
    }
    
    // MARK: -
    
    private func presentTermsScreen(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    private func presentQRCodeReader(completion: @escaping RegisterScene.QRCodeReaderCompletion) {
        self.runQRCodeReaderFlow(
            presentingViewController: self.navigationController.getViewController(),
            handler: { result in
                switch result {
                    
                case .canceled:
                    completion(.canceled)
                    
                case .success(let value, let metadataType):
                    completion(.success(value: value, metadataType: metadataType))
                }
        })
    }
}
