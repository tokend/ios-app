import UIKit
import TokenDSDK

class LocalAuthFlowController: BaseFlowController {
    
    typealias OnDidFinishForgotPassword = (_ newPassword: String) -> Void
    
    // MARK: - Private properties
    
    private let navigationController: NavigationControllerProtocol
    private let keychainManager: KeychainManagerProtocol
    private let activeKYCStorageManager: ActiveKYCStorageManagerProtocol
    private let localSignInWorker: LocalSignInWorkerProtocol
    private let onAuthorized: () -> Void
    private let onDidFinishForgotPassword: OnDidFinishForgotPassword
    private let onSignOut: () -> Void
    private let login: String
    
    // MARK: -
    
    init(
        login: String,
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        rootNavigation: RootNavigationProtocol,
        userDataManager: UserDataManagerProtocol,
        keychainManager: KeychainManagerProtocol,
        onAuthorized: @escaping () -> Void,
        onDidFinishForgotPassword: @escaping OnDidFinishForgotPassword,
        onSignOut: @escaping () -> Void,
        navigationController: NavigationControllerProtocol,
        activeKYCStorageManager: ActiveKYCStorageManagerProtocol
    ) {
        
        self.login = login
        self.keychainManager = keychainManager
        self.onAuthorized = onAuthorized
        self.onDidFinishForgotPassword = onDidFinishForgotPassword
        self.onSignOut = onSignOut
        self.navigationController = navigationController
        self.activeKYCStorageManager = activeKYCStorageManager
        
        self.localSignInWorker = LocalSignInWorker(
            userDataManager: userDataManager,
            keychainManager: keychainManager
        )
        
        super.init(
            appController: appController,
            flowControllerStack: flowControllerStack,
            rootNavigation: rootNavigation
        )
    }
}

// MARK: - Public

extension LocalAuthFlowController {
    
    func run(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        let vc: LocalSignInScene.ViewController = setupLocalSignIn()
        self.navigationController.setNavigationBarHidden(false, animated: true)
        self.navigationController.setViewControllers([vc], animated: true)
        vc.navigationController?.navigationBar.prefersLargeTitles = true
    }
}

// MARK: - Private

private extension LocalAuthFlowController {
    
    private func presentBiometricsAuthScreen(
        completion: @escaping (Bool) -> Void
    ) {
        
        let vc = setupBiometricsAuthScreen(
            onClose: { [weak self] in
                self?.navigationController
                    .getViewController()
                    .presentedViewController?
                    .dismiss(animated: false, completion: nil)
            },
            completion: completion
        )
        navigationController.getViewController().definesPresentationContext = true
        navigationController.present(vc, animated: false, completion: nil)
    }
    
    func setupLocalSignIn() -> LocalSignInScene.ViewController {
        let vc = LocalSignInScene.ViewController()
        
        let routing: LocalSignInScene.Routing = .init(
            onBiometrics: { [weak self] in
                self?.presentBiometricsAuthScreen(
                    completion: { (result) in
                        // TODO: -
                    }
                )
            },
            onForgotPassword: { [weak self] in
                self?.showForgotPassword()
            },
            onSignOut: { [weak self] in
                self?.onSignOut()
            },
            onSignIn: { [weak self] (password) in
                
                guard let login = self?.login else {
                    return
                }
                
                self?.localSignInWorker.performSignIn(
                    login: login,
                    passcode: password,
                    completion: { [weak self] (result) in
                        self?.navigationController.hideProgress()

                        switch result {
                        
                        case .success:
                            self?.onAuthorized()

                        case .error(error: let error):
                            switch error {
                            
                            case .wrongPasscode:
                                self?.navigationController.showErrorMessage(
                                    Localized(.authorization_error_wrong_login),
                                    completion: nil
                                )
                                
                            case .noSavedAccount:
                                // TODO: - Fix
                            break
                            }
                        }
                    }
                )
            }
        )
        
        let userAvatarUrlProvider: LocalSignInScene.UserAvatarUrlProviderProtocol = LocalSignInScene.UserAvatarUrlProvider(
            activeKYCStorageManager: self.activeKYCStorageManager
        )
        
        let biometricsInfoProvider: BiometricsInfoProvider = .init()
        
        LocalSignInScene.Configurator.configure(
            viewController: vc,
            routing: routing,
            login: self.login,
            userAvatarUrlProvider: userAvatarUrlProvider,
            biometricsInfoProvider: biometricsInfoProvider
        )
        
        return vc
    }
    
    private func setupBiometricsAuthScreen(
        onClose: @escaping () -> Void,
        completion: @escaping (Bool) -> Void
    ) -> UIViewController {
        
        let vc = BiometricsAuth.ViewController()
        vc.modalPresentationStyle = .overCurrentContext
        
        let authWorker = BiometricsAuth.BiometricsAuthWorker(
            keychainManager: self.keychainManager
        )
        
        let routing = BiometricsAuth.Routing(
            onAuthSucceeded: { [weak self] (account) in
                completion(true)
                onClose()
                self?.onAuthorized()
            },
            onAuthFailed: {
                completion(false)
                onClose()
            },
            onUserCancelled: {
                completion(false)
                onClose()
            },
            onUserFallback: {
                completion(false)
                onClose()
            }
        )
        
        BiometricsAuth.Configurator.configure(
            viewController: vc,
            authWorker: authWorker,
            routing: routing
        )
        
        return vc
    }
    
    func showForgotPassword() {
        
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
                self?.onDidFinishForgotPassword(password)
            },
            navigationController: navigationController
        )
        self.currentFlowController = flow
        flow.run(showRootScreen: { [weak self] (vc) in
            self?.navigationController.pushViewController(vc, animated: true)
        })
    }
}
