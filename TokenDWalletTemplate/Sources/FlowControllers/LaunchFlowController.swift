import UIKit
import TokenDSDK
import QRCodeReader

class LaunchFlowController: BaseFlowController {
    
    // MARK: - Private properties
    
    private let navigationController: NavigationControllerProtocol = NavigationController()
    private let userDataManager: UserDataManagerProtocol
    private let keychainManager: KeychainManagerProtocol
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
        
        self.navigationController.navigationBar.titleTextAttributes = [
            NSAttributedStringKey.font: Theme.Fonts.navigationBarBoldFont,
            NSAttributedStringKey.foregroundColor: Theme.Colors.textOnMainColor
        ]
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
        launchOptions: [UIApplicationLaunchOptionsKey: Any],
        userDataManager: UserDataManagerProtocol
        ) -> URL? {
        
        if let userActivityInfo = launchOptions[UIApplicationLaunchOptionsKey.userActivityDictionary] as? [String: Any],
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
            self.keychainManager.hasKeyDataForMainAccount(),
            self.userDataManager.hasWalletDataForMainAccount() {
            
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
            self?.navigationController.popViewController(true)
        })
        
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func setupRecoveryScreen(onSuccess: @escaping () -> Void) -> UpdatePassword.ViewController {
        let vc = UpdatePassword.ViewController()
        
        let submitPasswordHandler = UpdatePassword.RecoverWalletWorker(
            keyserverApi: self.flowControllerStack.keyServerApi,
            keychainManager: self.keychainManager,
            userDataManager: self.userDataManager,
            networkInfoFetcher: self.flowControllerStack.networkInfoFetcher
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
        
        vc.navigationItem.title = "Recovery"
        
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
        
        vc.navigationItem.title = "Verify Email"
        
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
        account: String,
        walletData: RegisterScene.Model.WalletData,
        seed: String
        ) {
        
        let vc = self.setupRecoverySeedScreen(account: account, walletData: walletData, seed: seed)
        
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func setupRecoverySeedScreen(
        account: String,
        walletData: RegisterScene.Model.WalletData,
        seed: String
        ) -> RecoverySeed.ViewController {
        
        let vc = RecoverySeed.ViewController()
        
        let routing = RecoverySeed.Routing(
            onShowMessage: { [weak self] message in
                self?.navigationController.showDialog(
                    title: message,
                    message: nil,
                    style: .alert,
                    options: [],
                    onSelected: { _ in },
                    onCanceled: nil
                )
            },
            onShowAlertDialog: { [weak self] (message, options, onSelected) in
                self?.navigationController.showDialog(
                    title: nil,
                    message: message,
                    style: .alert,
                    options: options,
                    onSelected: onSelected,
                    onCanceled: nil
                )
            },
            onProceed: { [weak self] in
                if walletData.verified {
                    self?.onAuthorized(account)
                } else {
                    self?.showVerifyEmailScreen(walletId: walletData.walletId)
                }
        })
        
        RecoverySeed.Configurator.configure(
            viewController: vc,
            seed: seed,
            routing: routing
        )
        
        vc.navigationItem.title = "Recovery Seed"
        vc.navigationItem.hidesBackButton = true
        
        return vc
    }
    
    private func showSignInScreenOnVerified() {
        let vc = self.setupRegisterScreen()
        
        self.navigationController.setViewControllers([vc], animated: true)
    }
    
    private func setupRegisterScreen() -> RegisterScene.ViewController {
        let vc = RegisterScene.ViewController()
        
        var termsUrl: URL?
        if var termsAddress = self.flowControllerStack.apiConfigurationModel.termsAddress {
            if !termsAddress.hasPrefix("http") {
                termsAddress = "https://\(termsAddress)"
            }
            termsUrl = URL(string: termsAddress)
        }
        let sceneModel = RegisterScene.Model.SceneModel.signInWithEmail(self.submittedEmail, termsUrl: termsUrl)
        
        let registrationWorker = RegisterScene.TokenDRegisterWorker(
            appController: self.appController,
            flowControllerStack: self.flowControllerStack,
            userDataManager: self.userDataManager,
            keychainManager: self.keychainManager,
            onSubmitEmail: { [weak self] (email) in
                self?.submittedEmail = email
        })
        
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
            onSuccessfulRegister: { [weak self] (account, walletData, recoverySeed) in
                self?.showRecoverySeedScreen(account: account, walletData: walletData, seed: recoverySeed)
            },
            onRecovery: { [weak self] in
                self?.showRecoveryScreen()
            },
            showDialogAlert: { [weak self] (title, message, options, onSelected, onCanceled) in
                self?.navigationController.showDialog(
                    title: title,
                    message: message,
                    style: .alert,
                    options: options,
                    onSelected: onSelected,
                    onCanceled: onCanceled
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
            routing: routing
        )
        
        vc.navigationItem.title = "TokenD"
        
        return vc
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
