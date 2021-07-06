import UIKit
import TokenDSDK
import TokenDWallet
import DLJSONAPI

class AppController {
    
    // MARK: - Public properties
    
    let rootNavigation: RootNavigationProtocol
    
    // MARK: - Private properties
    
    let flowControllerStack: FlowControllerStack
    var userDataManager: UserDataManagerProtocol & TFADataProviderProtocol
    var keychainManager: KeychainManagerProtocol
    let accountTypeManager: AccountTypeManagerProtocol
    private let notificationsRegisterer: FirebaseNotificationsRegistererProtocol?
    private lazy var reposControllerStack: ReposControllerStack = {
        return self.setupReposControllerStack()
    }()
    private lazy var managersControllerStack: ManagersControllerStack = {
        return self.setupManagersControllerStack()
    }()

    private let navigationController: NavigationControllerProtocol = NavigationController()
    
    private var currentFlowController: FlowControllerProtocol?
    
    private var launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    internal var lastUserActivityURL: URL?
    internal var userActivitySubscribers = [UserActivitySubscriber]()
    internal var lastOpenURL: URL?
    internal var openURLSubscribers = [OpenURLSubscriber]()
    private var unauthorizedSignOutInitiated: Bool = false
    
    // MARK: -
    
    init(
        rootNavigation: RootNavigationProtocol,
        apiConfigurationModel: APIConfigurationModel,
        notificationsRegisterer: FirebaseNotificationsRegistererProtocol?,
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?
        ) {
        
        self.rootNavigation = rootNavigation
        self.launchOptions = launchOptions
        self.notificationsRegisterer = notificationsRegisterer

        accountTypeManager = AccountTypeManager()
        
        let callbacks = ApiCallbacks(
            onTFARequired: { (_, _) in },
            onUnathorizedRequest: { _ in }
        )
        
        let callbacksV3 = JSONAPI.ApiCallbacks(
            onUnathorizedRequest: { _ in }
        )
        
        let network = AlamofireNetwork(
            onUnathorizedRequest: callbacks.onUnathorizedRequest
        )
        
        // TODO
        // network.startLogger()
        
        let queue = DispatchQueue(label: "io.tokend.resources", qos: .background, attributes: .concurrent)
        let resourcePool = ResourcePool(
            queue: queue
        )
        let networkV3 = JSONAPI.AlamofireNetwork(
            resourcePool: resourcePool,
            onUnathorizedRequest: callbacksV3.onUnathorizedRequest
        )
        
        // TODO
        // networkV3.startLogger()
        
        self.keychainManager = KeychainManager()
        self.userDataManager = UserDataManager(keychainManager: self.keychainManager)
        
        let keyDataProvider = RequestSignKeyDataProvider(keychainManager: self.keychainManager)
        let accountIdProvider = RequestSignAccountIdProvider(userDataManager: self.userDataManager)
        
        self.flowControllerStack = FlowControllerStack(
            apiConfigurationModel: apiConfigurationModel,
            tfaDataProvider: self.userDataManager,
            network: network,
            networkV3: networkV3,
            apiCallbacks: callbacks,
            apiCallbacksV3: callbacksV3,
            keyDataProvider: keyDataProvider,
            accountIdProvider: accountIdProvider,
            settingsManager: SettingsManager()
        )

        let newCallbacks = ApiCallbacks(
            onTFARequired: { [weak self] (input, cancelBlock) in
                self?.onTFARequired(tfaInput: input, cancel: cancelBlock)
            },
            onUnathorizedRequest: { _ in }
        )
        let newCallbacksV3 = JSONAPI.ApiCallbacks(
            onUnathorizedRequest: { _ in }
        )

        let newNetwork = AlamofireNetwork(
            onUnathorizedRequest: newCallbacks.onUnathorizedRequest
        )
        let newNetworkV3 = JSONAPI.AlamofireNetwork(
            resourcePool: resourcePool,
            onUnathorizedRequest: newCallbacksV3.onUnathorizedRequest
        )

        self.flowControllerStack.updateWith(
            apiConfigurationModel: apiConfigurationModel,
            tfaDataProvider: self.userDataManager,
            network: newNetwork,
            networkV3: newNetworkV3,
            apiCallbacks: newCallbacks,
            apiCallbacksV3: newCallbacksV3,
            keyDataProvider: keyDataProvider,
            accountIdProvider: accountIdProvider,
            settingsManager: self.flowControllerStack.settingsManager
        )
    }
    
    // MARK: - Public

    func onRootDidAppear() {
        rootNavigation.setRootContent(navigationController, transition: .fade, animated: false)
        self.runLaunchFlow(animated: false)
    }
    
    func applicationContinue(
        userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
        ) -> Bool {
        
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
    
    private func runLaunchFlow(animated: Bool) {
        if let mainAccount = self.userDataManager.getMainAccount(),
            let walletData = self.userDataManager.getWalletData(account: mainAccount) {
            
            let apiConfigurationModel = APIConfigurationModel(
                storageEndpoint: walletData.network.storageUrl,
                apiEndpoint: walletData.network.rootUrl,
                termsAddress: self.flowControllerStack.apiConfigurationModel.termsAddress,
                webClient: nil,
                downloadUrl: nil
            )
            self.updateFlowControllerStack(apiConfigurationModel, self.keychainManager)
        }
        
        let launchFlowController = LaunchFlowController(
            appController: self,
            flowControllerStack: self.flowControllerStack,
            rootNavigation: self.rootNavigation,
            userDataManager: self.userDataManager,
            keychainManager: self.keychainManager,
            accountTypeManager: accountTypeManager,
            onAuthorized: { [weak self] (account, accountType) in
                self?.runSignedInFlowController(account: account, accountType: accountType)
            },
            onSignOut: { [weak self] in
                self?.initiateSignOut()
            },
            navigationController: navigationController
        )
        self.currentFlowController = launchFlowController
        launchFlowController.start(animated: animated)
    }
    
    private func runSignedInFlowController(
        account: String,
        accountType: AccountType
    ) {
        guard let keychainDataProvider = KeychainDataProvider(
            account: account,
            keychainManager: self.keychainManager
            ) else {
                self.showErrorAlertAndSignout(message: Localized(.unable_to_read_keychain_data))
                return
        }
        
        guard let walletData = self.userDataManager.getWalletData(account: account),
            let accountId = AccountID(
                base32EncodedString: walletData.accountId,
                expectedVersion: .accountIdEd25519
            )
            else {
                self.showErrorAlertAndSignout(message: Localized(.unable_to_read_wallet_data))
                return
        }
        
        guard let userDataProvider = UserDataProvider(
            account: account,
            accountId: accountId,
            userDataManager: self.userDataManager
            ) else {
                self.showErrorAlertAndSignout(message: Localized(.unable_to_read_user_data))
                return
        }

        let transactionSigner: TransactionSigner = .init(
            keychainDataProvider: keychainDataProvider
        )
        
        let transactionSender: TransactionSender = .init(
            apiV3: self.reposControllerStack.apiV3.transactionsApi,
            transactionSigner: transactionSigner
        )

        let transactionCreator: TransactionCreator = .init(
            networkInfoFetcher: self.flowControllerStack.networkInfoFetcher
        )

        let latestChangeRoleProvider: LatestChangeRoleRequestProvider = .init(
            accountsApi: reposControllerStack.apiV3.accountsApi,
            originalAccountId: userDataProvider.walletData.accountId
        )
        
        let tfaManager: TFAManagerProtocol = TFAManager(
            tfaApi: flowControllerStack.api.tfaApi,
            userDataProvider: userDataProvider,
            handleSecret: { [weak self] (secret, seed, completion) in
                self?.currentFlowController?.handleTFASecret(secret, seed: seed, completion: completion)
            }
        )
        
        let managersController = ManagersController(
            managersControllerStack: self.managersControllerStack,
            keychainManager: self.keychainManager,
            userDataManager: self.userDataManager,
            settingsManager: self.flowControllerStack.settingsManager,
            transactionSender: transactionSender,
            transactionSigner: transactionSigner,
            transactionCreator: transactionCreator,
            userDataProvider: userDataProvider,
            keychainDataProvider: keychainDataProvider,
            latestChangeRoleRequestProvider: latestChangeRoleProvider,
            precisionProvider: self.flowControllerStack.precisionProvider,
            accountTypeManager: accountTypeManager,
            notificationsRegisterer: notificationsRegisterer,
            tfaManager: tfaManager
        )
        let reposController = ReposController(
            reposControllerStack: self.reposControllerStack,
            networkInfoRepo: self.flowControllerStack.networkInfoRepo,
            userDataProvider: userDataProvider,
            keychainDataProvider: keychainDataProvider,
            apiConfigurationModel: self.flowControllerStack.apiConfigurationModel,
            managersController: managersController
        )
        let flowController = SignedInFlowController(
            appController: self,
            flowControllerStack: self.flowControllerStack,
            reposController: reposController,
            managersController: managersController,
            userDataProvider: userDataProvider,
            keychainDataProvider: keychainDataProvider,
            rootNavigation: self.rootNavigation,
            accountType: accountType,
            onSignOut: { [weak self] in
                self?.performSignOut()
            },
            onAskToSignOut: { [weak self] in
                self?.initiateSignOut()
            },
            onBack: { [weak self] in
                self?.runLaunchFlow(animated: true)
            },
            navigationController: navigationController
        )
        self.currentFlowController = flowController
        flowController.run()
    }
    
    private func setupReposControllerStack() -> ReposControllerStack {
        return ReposControllerStack(
            api: self.flowControllerStack.api,
            apiV3: self.flowControllerStack.apiV3,
            keyServerApi: self.flowControllerStack.keyServerApi,
            storageUrl: self.flowControllerStack.apiConfigurationModel.storageEndpoint
        )
    }

    private func setupManagersControllerStack() -> ManagersControllerStack {
        return ManagersControllerStack(
            api: self.flowControllerStack.api,
            apiV3: self.flowControllerStack.apiV3,
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
            title: Localized(.sign_out),
            message: Localized(.are_you_sure_you_want_to_sign_out),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: Localized(.sign_out_and_erase),
            style: .default,
            handler: { [weak self] _ in
                self?.performSignOut()
        }))
        
        alert.addAction(UIAlertAction(
            title: Localized(.cancel),
            style: .cancel,
            handler: nil
        ))
        
        self.rootNavigation.presentAlert(alert, animated: true, completion: nil)
    }
    
    private func performSignOut(completion: (() -> Void)? = nil) {
        let signOutWorker: SignOutWorkerProtocol = SignOutWorker(
            userDataManager: self.userDataManager,
            keychainManager: self.keychainManager
        )
        
        signOutWorker.performSignOut({ [weak self] in

            self?.notificationsRegisterer?.unregisterFromNotifications()
            self?.accountTypeManager.resetType()
            self?.runLaunchFlow(animated: true)
            completion?()
        })
    }
    
    private func showErrorAlertAndSignout(
        message: String,
        completion: (() -> Void)? = nil
        ) {
        
        let alert = UIAlertController(
            title: Localized(.fatal_error),
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: Localized(.cancel),
            style: .cancel,
            handler: { [weak self] _ in
                self?.performSignOut(completion: { [weak self] in
                    self?.accountTypeManager.resetType()
                    self?.rootNavigation.hideBackgroundCover()
                    completion?()
                })
        }))
        
        self.rootNavigation.showBackgroundCover()
        self.rootNavigation.presentAlert(alert, animated: true, completion: nil)
    }
}

extension AppController: AppControllerProtocol {
    
    func updateFlowControllerStack(_ configuration: APIConfigurationModel, _ keychainManager: KeychainManagerProtocol) {
        self.keychainManager = keychainManager
        self.userDataManager = UserDataManager(keychainManager: keychainManager)
        
        let onUnauthoziedRequest: (String) -> Void = { [weak self] (message) in
            print(Localized(
                .unathorized_request,
                replace: [
                    .unathorized_request_replace_message: message
                ]
                )
            )
            DispatchQueue.main.async(execute: { [weak self] in
                self?.unauthorizedSignOutInitiated = true
                self?.showErrorAlertAndSignout(
                    message: Localized(.access_revoked_sign_in_required),
                    completion: { [weak self] in
                        self?.unauthorizedSignOutInitiated = false
                })
            })
        }
        
        let apiCallbacks = ApiCallbacks(
            onTFARequired: { [weak self] (input, cancelBlock) in
                self?.onTFARequired(tfaInput: input, cancel: cancelBlock)
            },
            onUnathorizedRequest: { (error) in
                onUnauthoziedRequest(error.localizedDescription)      
        })
        
        let apiCallbacksV3 = JSONAPI.ApiCallbacks(
            onUnathorizedRequest: { (error) in
                onUnauthoziedRequest(error.localizedDescription)
        })
        
        let network = AlamofireNetwork(
            onUnathorizedRequest: apiCallbacks.onUnathorizedRequest
        )
        
        let queue = DispatchQueue(
            label: "io.tokend.resources",
            qos: .background,
            attributes: .concurrent
        )
        
        let resourcePool = ResourcePool(
            queue: queue
        )
        let networkV3 = JSONAPI.AlamofireNetwork(
            resourcePool: resourcePool,
            onUnathorizedRequest: apiCallbacksV3.onUnathorizedRequest
        )
        
        let keyDataProvider = RequestSignKeyDataProvider(keychainManager: self.keychainManager)
        let accountIdProvider = RequestSignAccountIdProvider(userDataManager: self.userDataManager)
        
        self.flowControllerStack.updateWith(
            apiConfigurationModel: configuration,
            tfaDataProvider: self.userDataManager,
            network: network,
            networkV3: networkV3,
            apiCallbacks: apiCallbacks,
            apiCallbacksV3: apiCallbacksV3,
            keyDataProvider: keyDataProvider,
            accountIdProvider: accountIdProvider,
            settingsManager: SettingsManager()
        )
        
        self.reposControllerStack = self.setupReposControllerStack()
    }
    
    func getLaunchOptions() -> [UIApplication.LaunchOptionsKey: Any]? {
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
