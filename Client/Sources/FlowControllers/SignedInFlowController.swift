import UIKit
import TokenDWallet
import RxCocoa
import RxSwift
import TokenDSDK

class SignedInFlowController: BaseSignedInFlowController {
    
    // MARK: - Public properties
    
    static let backgroundTimeout: TimeInterval = 15 * 60
    
    private(set) var isAuthorized: Bool = true
    
    // MARK: - Private properties
    
    private var localAuthFlow: LocalAuthFlowController?
    private var timeoutSubscribeToken: TimerUIApplication.SubscribeToken = TimerUIApplication.SubscribeTokenInvalid
    private var backgroundTimer: Timer?
    private var backgroundToken: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid

    private lazy var fcmTokenUploader: FCMTokenUploaderProtocol = {
        FCMTokenUploader(
            api: flowControllerStack.api,
            userDataProvider: userDataProvider
        )
    }()

    private let navigationController: NavigationControllerProtocol

    private let disposeBag: DisposeBag = .init()
    
    // MARK: - Callbacks
    
    let onSignOut: () -> Void
    let onAskToSignOut: () -> Void
    let onBack: () -> Void
    
    // MARK: -
    
    init(
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        reposController: ReposController,
        managersController: ManagersController,
        userDataProvider: UserDataProviderProtocol,
        keychainDataProvider: KeychainDataProviderProtocol,
        rootNavigation: RootNavigationProtocol,
        accountType: AccountType,
        onSignOut: @escaping () -> Void,
        onAskToSignOut: @escaping () -> Void,
        onBack: @escaping () -> Void,
        navigationController: NavigationControllerProtocol
        ) {
        
        self.onSignOut = onSignOut
        self.onAskToSignOut = onAskToSignOut
        self.onBack = onBack

        self.navigationController = navigationController

        super.init(
            appController: appController,
            flowControllerStack: flowControllerStack,
            reposController: reposController,
            managersController: managersController,
            userDataProvider: userDataProvider,
            keychainDataProvider: keychainDataProvider,
            rootNavigation: rootNavigation
        )
        
        self.timeoutSubscribeToken = TimerUIApplication.subscribeForTimeoutNotification(handler: { [weak self] in
            self?.isAuthorized = false
            self?.stopUserActivityTimer()
            _ = self?.checkIsAuthorized()
        })
    }
    
    deinit {
        TimerUIApplication.unsubscribeFromTimeoutNotification(self.timeoutSubscribeToken)
        self.timeoutSubscribeToken = TimerUIApplication.SubscribeTokenInvalid
    }
    
    // MARK: - Public
    
    public func run() {
        self.checkRecovery()
    }
    
    // MARK: - Overridden
    
    override func applicationDidEnterBackground() {
        guard self.localAuthFlow == nil else { return }
        
        self.startBackgroundTimer()
    }
    
    override func applicationWillEnterForeground() {
        guard self.localAuthFlow == nil else { return }
        
        self.stopBackgroundTimer()
    }
    
    override func applicationWillResignActive() {
        guard self.localAuthFlow == nil else { return }
        
        self.rootNavigation.showBackgroundCover()
    }
    
    override func applicationDidBecomeActive() {
        self.rootNavigation.hideBackgroundCover()
        
        if self.checkIsAuthorized() {
            self.currentFlowController?.applicationDidBecomeActive()
        }
    }
}

// MARK: - Private methods

private extension SignedInFlowController {

    func checkRecovery() {

        let recoveryFlowController: RecoveryFlowController = .init(
            appController: appController,
            flowControllerStack: flowControllerStack,
            reposController: reposController,
            managersController: managersController,
            userDataProvider: userDataProvider,
            keychainDataProvider: keychainDataProvider,
            rootNavigation: rootNavigation,
            onRecoveryFinished: { [weak self] in
                self?.currentFlowController = nil
                self?.checkKYC()
            },
            onRecoveryFailed: { [weak self] in
                self?.currentFlowController = nil
                self?.onSignOut()
            },
            navigationController: navigationController
        )

        currentFlowController = recoveryFlowController
        recoveryFlowController.run()
    }

    func checkKYC() {

        let kycFlowController: KYCFlowController = .init(
            appController: appController,
            flowControllerStack: flowControllerStack,
            reposController: reposController,
            managersController: managersController,
            userDataProvider: userDataProvider,
            keychainDataProvider: keychainDataProvider,
            rootNavigation: rootNavigation,
            onKYCFinished: { [weak self] in
                self?.currentFlowController = nil
                self?.showMainFlow()
                self?.checkNotifications()
            },
            onKYCFailed: { [weak self] in
                self?.currentFlowController = nil
                self?.onSignOut()
            },
            onBack: { [weak self] in
                self?.currentFlowController = nil
                self?.onBack()
            },
            navigationController: navigationController
        )

        currentFlowController = kycFlowController
        kycFlowController.run()
    }

    func checkNotifications() {

        // Define NOTIFICATIONS in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use notifications
        #if NOTIFICATIONS
        let permissionFlowController: PermissionRequestFlowController = .init(
            appController: appController,
            flowControllerStack: flowControllerStack,
            rootNavigation: rootNavigation,
            resource: .notifications,
            onGranted: { [weak self] in
                self?.currentFlowController = nil
                self?.registerDeviceToken()
            },
            onDenied: { [weak self] in
                self?.currentFlowController = nil
            }
        )

        currentFlowController = permissionFlowController
        permissionFlowController.run(handleRepeatedRequest: false)
        #else
        // TODO: - Show next screen
        #endif
    }

    func registerDeviceToken() {

        managersController
            .notificationsRegisterer?
            .observeFCMToken()
            .subscribe(onNext: { [weak self] (token) in

                if let token = token {

                    self?.fcmTokenUploader.uploadToken(
                        token,
                        completion: { (_) in }
                    )
                }
            })
            .disposed(by: disposeBag)

        managersController.notificationsRegisterer?.registerForNotifications()
    }
    
    func runReposPreload() {
        // TODO: - Add if needed
    }
    
    func showMainFlow() {
        let flow = setupMainFlow()
        flow.run(
            showRootScreen: { [weak self] (controller) in
                self?.rootNavigation.setRootContent(
                    controller,
                    transition: .fade,
                    animated: true
                )
            },
            selectedTab: .balances
        )
        currentFlowController = flow
    }
    
    func setupMainFlow(
    ) -> TabBarFlowController {
        let tabBarFlow: TabBarFlowController = .init(
            appController: appController,
            flowControllerStack: flowControllerStack,
            reposController: reposController,
            managersController: managersController,
            userDataProvider: userDataProvider,
            keychainDataProvider: keychainDataProvider,
            rootNavigation: rootNavigation,
            onAskSignOut: onAskToSignOut,
            onPerformSignOut: onSignOut
        )
        
        return tabBarFlow
    }
    
    // MARK: - Timeout management
    
    func startUserActivityTimer() {
        TimerUIApplication.startIdleTimer()
    }
    
    func stopUserActivityTimer() {
        TimerUIApplication.stopIdleTimer()
    }
    
    func startBackgroundTimer() {
        self.backgroundToken = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        self.backgroundTimer = Timer.scheduledTimer(
            withTimeInterval: SignedInFlowController.backgroundTimeout,
            repeats: false,
            block: { [weak self] _ in
                self?.isAuthorized = false
                self?.stopBackgroundTimer()
        })
    }
    
    func stopBackgroundTimer() {
        self.backgroundTimer?.invalidate()
        self.backgroundTimer = nil
        UIApplication.shared.endBackgroundTask(self.backgroundToken)
        self.backgroundToken = UIBackgroundTaskIdentifier.invalid
    }
    
    func checkIsAuthorized() -> Bool {
        if !self.isAuthorized && UIApplication.shared.applicationState == .active {
//            self.runLocalAuthByTimeout()
            return false
        }
        
        return true
    }
    
//    func runLocalAuthByTimeout() {
//        guard self.localAuthFlow == nil else {
//            return
//        }
//
//        let flow = LocalAuthFlowController(
//            account: self.userDataProvider.account,
//            appController: self.appController,
//            flowControllerStack: self.flowControllerStack,
//            rootNavigation: self.rootNavigation,
//            userDataManager: self.managersController.userDataManager,
//            keychainManager: self.managersController.keychainManager,
//            onAuthorized: { [weak self] in
//                self?.onLocalAuthSucceded()
//            },
//            onSignOut: { [weak self] in
//                self?.onSignOut()
//            },
//            navigationController: navigationController
//        )
//        self.localAuthFlow = flow
//        flow.run(showRootScreen: nil, animated: true)
//    }
    
    func onLocalAuthSucceded() {
        self.isAuthorized = true
        self.localAuthFlow = nil
        self.startUserActivityTimer()
    }
}
