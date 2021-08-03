import UIKit

class ChangePasswordFlowController: BaseSignedInFlowController {
    
    typealias OnBack = () -> Void
    typealias OnDidChangePassword = () -> Void
    
    // MARK: Private properties
    
    private let onBack: OnBack
    private let onDidChangePassword: OnDidChangePassword
    private lazy var changePasswordWorker: PasswordChangerProtocol = initPasswordChanger()
    private let navigationController: NavigationControllerProtocol
    
    // MARK:
    
    init(
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        reposController: ReposController,
        managersController: ManagersController,
        userDataProvider: UserDataProviderProtocol,
        keychainDataProvider: KeychainDataProviderProtocol,
        rootNavigation: RootNavigationProtocol,
        onBack: @escaping OnBack,
        onDidChangePassword: @escaping OnDidChangePassword,
        navigationController: NavigationControllerProtocol
    ) {
        
        self.onBack = onBack
        self.onDidChangePassword = onDidChangePassword
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
    }
}

// MARK: Private methods

private extension ChangePasswordFlowController {
    
    func initPasswordChanger(
    ) -> PasswordChangerProtocol! {
        
        var keysProvider: KeyServerAPIKeysProviderProtocol!
        
        repeat {
            keysProvider = try? ContoPassPasswordChangerKeysProvider(
               keychainDataProvider: keychainDataProvider
           )
        } while keysProvider == nil
        
        let changer: BasePasswordChanger = .init(
            transactionCreator: managersController.transactionCreator,
            keyServerApi: flowControllerStack.keyServerApi,
            accountsApiV3: flowControllerStack.apiV3.accountsApi,
            userDataProvider: userDataProvider,
            keychainManager: managersController.keychainManager,
            keysProvider: keysProvider
        )
        
        return changer
    }
    
    func initChangePasswordScreen(
        onBack: @escaping () -> Void
    ) -> UIViewController {
        
        let controller: ChangePasswordScene.ViewController = .init()
        
        let routing: ChangePasswordScene.Routing = .init(
            onBackAction: {
                onBack()
            },
            onChangePassword: { [weak self] (old, new) in
                self?.navigationController.showProgress()
                self?.changePasswordWorker.changePassword(
                    oldPassword: old,
                    newPassword: new,
                    completion: { [weak self] (result) in
                        DispatchQueue.main.async { [weak self] in
                            self?.navigationController.hideProgress()
                            
                            switch result {
                            
                            case .failure(let error):
                                
                                switch error {
                                
                                case PasswordChangerError.wrongOldPassword:
                                    self?.navigationController.showErrorMessage(
                                        Localized(.change_password_wrong_old_password_error),
                                        completion: nil
                                    )
                                    
                                default:
                                    self?.navigationController.showErrorMessage(
                                        error.localizedDescription,
                                        completion: nil
                                    )
                                }
                                
                            case .success:
                                onBack()
                            }
                        }
                    }
                )
            }
        )
        
        ChangePasswordScene.Configurator.configure(
            viewController: controller,
            routing: routing
        )
        
        return controller
    }
}

// MARK: Public methods

extension ChangePasswordFlowController {
    
    func run(
        _ showRootScreen: (UIViewController) -> Void
    ) {
        
        showRootScreen(
            initChangePasswordScreen(
                onBack: { [weak self] in
                    self?.onBack()
                }
            )
        )
    }
}
