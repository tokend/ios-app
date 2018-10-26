import UIKit
import TokenDSDK
import TokenDWallet

protocol AppControllerProtocol: class {
    func updateFlowControllerStack(_ configuration: APIConfigurationModel)
    
    func addUserAcivity(subscriber: UserActivitySubscriber)
    func removeUserAcivity(subscriber: UserActivitySubscriber)
    
    func getLaunchOptions() -> [UIApplicationLaunchOptionsKey: Any]?
    func launchOptionsUrlHandled(url: URL)
    func getLastUserActivityWebLink() -> URL?
    func lastUserActivityWebLinkHandled(url: URL)
}

class AppController {
    
    // MARK: - Public properties
    
    let rootNavigation: RootNavigationProtocol
    
    // MARK: - Private properties
    
    let flowControllerStack: FlowControllerStack
    let userDataManager: UserDataManagerProtocol & TFADataProviderProtocol
    let keychainManager: KeychainManagerProtocol
    private lazy var reposControllerStack: ReposControllerStack = {
        return self.setupReposControllerStack()
    }()
    
    private var currentFlowController: FlowControllerProtocol?
    
    private var launchOptions: [UIApplicationLaunchOptionsKey: Any]?
    internal var lastUserActivityURL: URL?
    internal var userActivitySubscribers = [UserActivitySubscriber]()
    
    // MARK: -
    
    init(
        rootNavigation: RootNavigationProtocol,
        apiConfigurationModel: APIConfigurationModel,
        launchOptions: [UIApplicationLaunchOptionsKey: Any]?
        ) {
        
        self.rootNavigation = rootNavigation
        self.launchOptions = launchOptions
        
        let callbacks = ApiCallbacks(onTFARequired: { (_, _) in })
        
        self.keychainManager = KeychainManager()
        self.userDataManager = UserDataManager(keychainManager: self.keychainManager)
        
        let keyDataProvider = RequestSignKeyDataProvider(keychainManager: self.keychainManager)
        
        self.flowControllerStack = FlowControllerStack(
            apiConfigurationModel: apiConfigurationModel,
            tfaDataProvider: self.userDataManager,
            userAgent: AppController.getUserAgent(),
            apiCallbacks: callbacks,
            keyDataProvider: keyDataProvider,
            settingsManager: SettingsManager()
        )
    }
    
    // MARK: - Public
    
    func onRootWillAppear() {
        self.runLaunchFlow()
    }
    
    func applicationContinue(userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        return self.handle(userActivity: userActivity)
    }
    
    func applicationDidEnterBackground() {
        self.currentFlowController?.applicationDidEnterBackground()
    }
    
    func applicationWillEnterForeground() {
        self.currentFlowController?.applicationWillEnterForeground()
    }
    
    func applicationDidBecomeActive() {
        self.currentFlowController?.applicationDidBecomeActive()
    }
    
    func applicationWillResignActive() {
        self.currentFlowController?.applicationWillResignActive()
    }
    
    // MARK: - Private
    
    private func runLaunchFlow() {
        self.updateFlowControllerStack(self.flowControllerStack.apiConfigurationModel)
        
        let launchFlowController = LaunchFlowController(
            appController: self,
            flowControllerStack: self.flowControllerStack,
            rootNavigation: self.rootNavigation,
            userDataManager: self.userDataManager,
            keychainManager: self.keychainManager,
            onAuthorized: { [weak self] (account) in
                self?.runSignedInFlowController(account: account)
            },
            onSignOut: { [weak self] in
                self?.initiateSignOut()
        })
        self.currentFlowController = launchFlowController
        launchFlowController.start()
    }
    
    private func runSignedInFlowController(account: String) {
        guard let keychainDataProvider = KeychainDataProvider(
            account: account,
            keychainManager: self.keychainManager
            ) else {
                self.showErrorAlertAndSignout(message: "Unable to read keychain data")
                return
        }
        
        guard let walletData = self.userDataManager.getWalletData(account: account),
            let accountId = AccountID(
                base32EncodedString: walletData.accountId,
                expectedVersion: .accountIdEd25519
            )
            else {
                self.showErrorAlertAndSignout(message: "Unable to read wallet data")
                return
        }
        
        guard let userDataProvider = UserDataProvider(
            account: account,
            accountId: accountId,
            userDataManager: self.userDataManager
            ) else {
                self.showErrorAlertAndSignout(message: "Unable to read user data")
                return
        }
        
        let transactionSender: TransactionSender = TransactionSender(
            api: self.reposControllerStack.api.transactionsApi,
            keychainDataProvider: keychainDataProvider
        )
        
        let accountRepo = AccountRepo(
            api: self.reposControllerStack.api,
            originalAccountId: walletData.accountId
        )
        let balancesRepo = BalancesRepo(
            api: self.reposControllerStack.api.balancesApi,
            transactionSender: transactionSender,
            originalAccountId: walletData.accountId,
            accountId: userDataProvider.accountId,
            walletId: walletData.walletId,
            networkInfoFetcher: self.flowControllerStack.networkInfoFetcher
        )
        
        let reposController = ReposController(
            reposControllerStack: self.reposControllerStack,
            accountRepo: accountRepo,
            balancesRepo: balancesRepo,
            networkInfoRepo: self.flowControllerStack.networkInfoFetcher,
            userDataProvider: userDataProvider,
            keychainDataProvider: keychainDataProvider,
            originalAccountId: walletData.accountId
        )
        let managersController = ManagersController(
            accountRepo: accountRepo,
            networkInfoRepo: self.flowControllerStack.networkInfoFetcher,
            keychainManager: self.keychainManager,
            userDataManager: self.userDataManager,
            settingsManager: self.flowControllerStack.settingsManager,
            transactionSender: transactionSender,
            userDataProvider: userDataProvider
        )
        let flowController = SignedInFlowController(
            appController: self,
            flowControllerStack: self.flowControllerStack,
            reposController: reposController,
            managersController: managersController,
            userDataProvider: userDataProvider,
            keychainDataProvider: keychainDataProvider,
            rootNavigation: self.rootNavigation,
            onSignOut: { [weak self] in
                self?.initiateSignOut()
            },
            onLocalAuthRecoverySucceeded: { [weak self] in
                self?.runLaunchFlow()
        })
        self.currentFlowController = flowController
        flowController.run()
    }
    
    private func setupReposControllerStack() -> ReposControllerStack {
        return ReposControllerStack(
            api: self.flowControllerStack.api,
            keyServerApi: self.flowControllerStack.keyServerApi,
            storageUrl: self.flowControllerStack.apiConfigurationModel.storageEndpoint
        )
    }
    
    private func onTFARequired(tfaInput: ApiCallbacks.TFAInput, cancel: @escaping () -> Void) {
        self.currentFlowController?.performTFA(tfaInput: tfaInput, cancel: cancel)
    }
    
    // MARK: - Sign Out
    
    private func initiateSignOut() {
        let alert = UIAlertController(
            title: "Sign Out",
            message: "Are you sure you want to Sign Out and Erase All Data from device?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: "Sign Out and Erase",
            style: .default,
            handler: { [weak self] _ in
                self?.performSignOut()
        }))
        
        alert.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: nil
        ))
        
        self.rootNavigation.presentAlert(alert, animated: true, completion: nil)
    }
    
    private func performSignOut(completion: (() -> Void)? = nil) {
        let signOutWorker = RegisterScene.LocalSignInWorker(
            userDataManager: self.userDataManager,
            keychainManager: self.keychainManager
        )
        
        signOutWorker.performSignOut(completion: { [weak self] in
            self?.runLaunchFlow()
            completion?()
        })
    }
    
    private func showErrorAlertAndSignout(message: String) {
        let alert = UIAlertController(
            title: "Fatal Error",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { [weak self] _ in
                self?.performSignOut(completion: { [weak self] in
                    self?.rootNavigation.hideBackgroundCover()
                })
        }))
        
        self.rootNavigation.showBackgroundCover()
        self.rootNavigation.presentAlert(alert, animated: true, completion: nil)
    }
    
    // MARK: - System Info
    
    static private func getUserAgent() -> String {
        let appPrefix = "TOKEND_WALLET"
        let bundleName: String = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? ""
        let version: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let deviceName = UIDevice.current.name
        let platform = self.platform()
        let systemName = UIDevice.current.systemName
        let systemVersion = UIDevice.current.systemVersion
        
        let components = [
            appPrefix,
            bundleName,
            version,
            deviceName,
            platform
        ]
        let componentsJoined = components.joined(separator: "|")
        
        let userAgent = [
            componentsJoined,
            systemName,
            systemVersion
            ].joined(separator: " ")
        
        return userAgent
    }
    
    static private func platform() -> String {
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(
            bytes: Data(
                bytes: &sysinfo.machine,
                count: Int(_SYS_NAMELEN)
            ),
            encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }
}

extension AppController: AppControllerProtocol {
    func updateFlowControllerStack(_ configuration: APIConfigurationModel) {
        let apiCallbacks = ApiCallbacks(onTFARequired: { [weak self] (input, cancelBlock) in
            self?.onTFARequired(tfaInput: input, cancel: cancelBlock)
        })
        
        let keyDataProvider = RequestSignKeyDataProvider(keychainManager: self.keychainManager)
        
        self.flowControllerStack.updateWith(
            apiConfigurationModel: configuration,
            tfaDataProvider: self.userDataManager,
            userAgent: AppController.getUserAgent(),
            apiCallbacks: apiCallbacks,
            keyDataProvider: keyDataProvider,
            settingsManager: SettingsManager()
        )
        
        self.reposControllerStack = self.setupReposControllerStack()
    }
    
    func getLaunchOptions() -> [UIApplicationLaunchOptionsKey: Any]? {
        return self.launchOptions
    }
    
    func launchOptionsUrlHandled(url: URL) {
        self.launchOptions = nil
    }
    
    func getLastUserActivityWebLink() -> URL? {
        return self.lastUserActivityURL
    }
    
    func lastUserActivityWebLinkHandled(url: URL) {
        if self.lastUserActivityURL == url {
            self.lastUserActivityURL = nil
        }
    }
}
