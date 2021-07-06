import UIKit
import TokenDSDK
import TokenDWallet

class LaunchFlowController: BaseFlowController {

    typealias OnAuthorized = (
        _ login: String,
        _ accountType: AccountType
    ) -> Void

    // MARK: - Private properties
    
    private let navigationController: NavigationControllerProtocol
    private var userDataManager: UserDataManagerProtocol
    private var keychainManager: KeychainManagerProtocol
    private let accountTypeManager: AccountTypeManagerProtocol
    private let onAuthorized: OnAuthorized
    private let onSignOut: () -> Void

    private let registrationChecker: RegistrationCheckerProtocol
    private lazy var accountTypeChecker: AccountTypeCheckerProtocol! = initAccountTypeChecker()
    private lazy var registerWorker: RegisterWorkerProtocol! = initRegisterWorker()

    private var login: String?
    private var cachedLoginWorker: LoginWorkerProtocol!

    // MARK: -

    init(
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        rootNavigation: RootNavigationProtocol,
        userDataManager: UserDataManagerProtocol,
        keychainManager: KeychainManagerProtocol,
        accountTypeManager: AccountTypeManagerProtocol,
        onAuthorized: @escaping OnAuthorized,
        onSignOut: @escaping  () -> Void,
        navigationController: NavigationControllerProtocol
    ) {
        
        self.userDataManager = userDataManager
        self.keychainManager = keychainManager
        self.accountTypeManager = accountTypeManager
        self.onAuthorized = onAuthorized
        self.onSignOut = onSignOut
        self.navigationController = navigationController
        self.registrationChecker = RegistrationChecker(
            keyServerApi: flowControllerStack.keyServerApi
        )

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

    override func performTFA(tfaInput: ApiCallbacks.TFAInput, cancel: @escaping () -> Void) {

        if let currentFlowController = currentFlowController {
            currentFlowController.performTFA(tfaInput: tfaInput, cancel: cancel)
        }
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
        
        return false
    }
    
    func start(animated: Bool) {
//        var launchUrl: URL?
//        if let launchOptions = self.appController.getLaunchOptions() {
//            launchUrl = LaunchFlowController.canHandle(
//                launchOptions: launchOptions,
//                userDataManager: self.userDataManager
//            )
//        }

        if let login = self.userDataManager.getMainAccount(),
            self.userDataManager.hasWalletDataForMainAccount(),
            !self.userDataManager.isSignedViaAuthenticator() {
            
            self.runLocalAuthFlow(login: login, animated: animated)
        }  else {

            // TODO: - Implement
            self.startFrom(vcs: [], animated: animated)
        }
    }
}

// MARK: - Private

private extension LaunchFlowController {

    typealias AccountTypeCompletion = (_ accountType: AccountType?) -> Void
    
    func runLocalAuthFlow(
        login: String,
        animated: Bool
    ) {

        accountTypeManager.setType(accountTypeManager.getType())

        let flow = LocalAuthFlowController(
            login: login,
            appController: self.appController,
            flowControllerStack: self.flowControllerStack,
            rootNavigation: self.rootNavigation,
            keychainManager: self.keychainManager,
            onAuthorized: { [weak self] in
                
                self?.navigationController.showProgress()
                self?.checkAccountType(
                    login: login,
                    completion: { [weak self] (accountType) in
                        self?.navigationController.hideProgress()
                        if let type = accountType {

                            self?.accountTypeManager.setType(type)
                            self?.onAuthorized(login, type)
                        }
                })
            },
            onDidFinishForgotPassword: { [weak self] (password) in
                
                self?.onDidFinishForgotPassword(
                    login: login,
                    password: password
                )
        },
            onSignOut: { [weak self] in
                self?.onSignOut()
            },
            navigationController: navigationController
        )
        self.currentFlowController = flow
        flow.run(
            showRootScreen: { [weak self] (viewController) in
                
                self?.navigationController.setViewControllers(
                    [viewController],
                    animated: animated
                )
            }
        )
    }
    
    func startFrom(vcs: [UIViewController], animated: Bool) {
        self.navigationController.setViewControllers(vcs, animated: animated)
    }
    
    func loginWorker(
        for login: String
    ) -> LoginWorkerProtocol! {
        
        guard self.login != login
        else {
            return cachedLoginWorker
        }
        
        self.login = login
        
        // TODO: - Implement
//        cachedLoginWorker = BaseLoginWorker(
//            walletDataProvider: <#T##WalletDataProviderProtocol#>,
//            userDataManager: userDataManager,
//            keychainManager: keychainManager
//        )
        return cachedLoginWorker
    }
    
    func initAccountTypeChecker() -> AccountTypeCheckerProtocol! {
        
        // TODO: - Implement
        return nil
    }
    
    func initRegisterWorker() -> RegisterWorkerProtocol! {
        
        // TODO: - Implement
//        return BaseRegisterWorker(
//            keyServerApi: flowControllerStack.keyServerApi,
//            keysProvider: <#T##KeyServerAPIKeysProviderProtocol#>
//        )
        return nil
    }
    
    func showForgotPassword(
        login: String
    ) {

        let lastViewController = navigationController.topViewController
        let flow = ForgotPasswordFlowController(
            appController: appController,
            flowControllerStack: flowControllerStack,
            rootNavigation: rootNavigation,
            keychainManager: keychainManager,
            onDidFinishForgotPassword: { [weak self] (password) in
                self?.currentFlowController = nil
                if let last = lastViewController {
                    self?.navigationController.popToViewController(last, animated: true)
                } else {
                    self?.navigationController.popViewController(true)
                }
                self?.onDidFinishForgotPassword(
                    login: login,
                    password: password
                )
            },
            navigationController: navigationController
        )
        self.currentFlowController = flow
        flow.run(showRootScreen: { [weak self] (vc) in
            self?.navigationController.pushViewController(vc, animated: true)
        })
    }
    
    func onDidFinishForgotPassword(
        login: String,
        password: String
    ) {

        navigationController.showProgress()
        checkAccountType(
            login: login,
            completion: { [weak self] (accountType) in
                if let type = accountType {
                    self?.accountTypeManager.setType(type)
                    self?.loginWorker(for: login)
                        .loginAction(
                            login: login,
                            password: password,
                            completion: { [weak self] (result) in
                                self?.navigationController.hideProgress()
                                
                                switch result {
                                
                                case .success(let login):
                                    self?.onAuthorized(login, type)
                                    
                                case .failure:
                                    // FIXME: - Set valid error
                                    self?.navigationController.showErrorMessage(Localized(.error_unknown), completion: nil)
                                }
                            })
                } else {
                    self?.navigationController.hideProgress()
                    // FIXME: - Set valid error
                    self?.navigationController.showErrorMessage(Localized(.error_unknown), completion: nil)
                }
        })
    }
    
    func checkAccountType(
        login: String,
        completion: @escaping AccountTypeCompletion
    ) {

        accountTypeChecker.checkAccountType(
            login: login,
            completion: { [weak self] (result) in
                switch result {
                case .failure(let error):
                    completion(nil)
                    let errorMessage: String
                    switch error {
                    case .unknown,
                         .error:
                        // FIXME: - Set valid error
                        errorMessage = Localized(.error_unknown)
                    case .notInvited:
                        // FIXME: - Set valid error
                        errorMessage = Localized(.error_unknown)
                    case .unsupportedAccountType:
                        // FIXME: - Set valid error
                        errorMessage = Localized(.error_unknown)
                    }
                    self?.navigationController.showErrorMessage(
                        errorMessage,
                        completion: nil
                    )
                case .success(let accountType):
                    completion(accountType)
                }
        })
    }
}
