import Foundation
import TokenDSDK

class ChangeLoginFlowController: BaseFlowController {
    
    typealias OnBack = () -> Void
    
    typealias OnDidChangeLogin = (
        _ login: String,
        _ password: String
    ) -> Void
    
    private let onBack: OnBack
    private let onDidChangeLogin: OnDidChangeLogin
    private let navigationController: NavigationControllerProtocol
    private var keychainManager: KeychainManagerProtocol

    // MARK: -

    init(
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        rootNavigation: RootNavigationProtocol,
        onDidChangeLogin: @escaping OnDidChangeLogin,
        onBack: @escaping OnBack,
        navigationController: NavigationControllerProtocol,
        keychainManager: KeychainManagerProtocol
    ) {

        self.onBack = onBack
        self.onDidChangeLogin = onDidChangeLogin
        self.navigationController = navigationController
        self.keychainManager = keychainManager

        super.init(
            appController: appController,
            flowControllerStack: flowControllerStack,
            rootNavigation: rootNavigation
        )
    }

    override func performTFA(tfaInput: ApiCallbacks.TFAInput, cancel: @escaping () -> Void) {

        if let currentFlowController = currentFlowController {
            currentFlowController.performTFA(tfaInput: tfaInput, cancel: cancel)
        }
    }

    func run() { }
}

// MARK: - Private methods

private extension ChangeLoginFlowController {

    func changePhoneNumber(
        oldLogin: String,
        newLogin: String,
        password: String
    ) {

        navigationController.showProgress()
        loginChanger().changeLogin(
            oldLogin: oldLogin,
            newLogin: newLogin,
            password: password,
            completion: { [weak self] (result) in
                
                self?.navigationController.hideProgress()
                
                switch result {
                
                case .failure(let error):
                    
                    let errorString: String
                    switch error {
                    
                    case KeyServerApi.GetWalletError.wrongPassword:
                        // FIXME: - Set valid error
                        errorString = Localized(.error_unknown)
                        
                    default:
                        // FIXME: - Set valid error
                        errorString = Localized(.error_unknown)
                    }
                    
                    self?.navigationController.showErrorMessage(
                        errorString,
                        completion: nil
                    )
                    
                case .success:
                    self?.onDidChangeLogin(
                        newLogin,
                        password
                    )
                }
            })
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
            onDidFinishForgotPassword: { [weak self] (_) in
                self?.currentFlowController = nil
                if let last = lastViewController {
                    self?.navigationController.popToViewController(last, animated: true)
                } else {
                    self?.navigationController.popViewController(true)
                }
            },
            navigationController: navigationController
        )
        self.currentFlowController = flow
        flow.run(showRootScreen: { [weak self] (vc) in
            self?.navigationController.pushViewController(vc, animated: true)
        })
    }

    func loginChanger(
    ) -> LoginChangerProtocol! {

        // FIXME: - Implement
//        return BaseLoginChanger(
//            flowControllerStack: self.flowControllerStack,
//            walletDataProvider: self.walletDataProvider
//        )
        return nil
    }
}
