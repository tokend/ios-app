import UIKit
import TokenDSDK

class ForgotPasswordFlowController: BaseFlowController {

    typealias OnDidFinishForgotPassword = (
        _ newPassword: String
    ) -> Void

    // MARK: - Private properties

    private var keychainManager: KeychainManagerProtocol
    private let onDidFinishForgotPassword: OnDidFinishForgotPassword
    private let navigationController: NavigationControllerProtocol
    private var cachedForgotPasswordWorker: ForgotPasswordWorkerProtocol!
    private var login: String?

    // MARK: -

    init(
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        rootNavigation: RootNavigationProtocol,
        keychainManager: KeychainManagerProtocol,
        onDidFinishForgotPassword: @escaping OnDidFinishForgotPassword,
        navigationController: NavigationControllerProtocol
    ) {

        self.keychainManager = keychainManager
        self.onDidFinishForgotPassword = onDidFinishForgotPassword
        self.navigationController = navigationController

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

    // MARK: - Public

    func run(
        showRootScreen: ((_ vc: UIViewController) -> Void)
    ) { }
}

// MARK: - Private

private extension ForgotPasswordFlowController {

    func forgotPasswordWorker(
    ) throws -> ForgotPasswordWorkerProtocol! {
        
        if let cached = cachedForgotPasswordWorker {
            return cached
        }
        
        // FIXME: - Implement
//        cachedForgotPasswordWorker = BaseForgotPasswordWorker(
//            keyServerApi: flowControllerStack.keyServerApi,
//            keychainManager: keychainManager,
//            keysProvider: <#T##KeyServerAPIKeysProviderProtocol#>
//        )
        
        return cachedForgotPasswordWorker
    }
    
    func forgotPassword(
        login: String,
        newPassword: String
    ) {
        
        self.login = login
        navigationController.showProgress()
        do {
            try forgotPasswordWorker()
            .changePassword(
                login: login,
                newPassword: newPassword,
                completion: { [weak self] (result) in
                    
                    self?.navigationController.hideProgress()
                    
                    switch result {
                    
                    case .failure:
                        self?.navigationController.showErrorMessage(Localized(.error_unknown), completion: nil)
                        
                    case .success:
                        self?.onDidFinishForgotPassword(newPassword)
                    }
                }
            )
        } catch {
            navigationController.hideProgress()
            navigationController.showErrorMessage(Localized(.error_unknown), completion: nil)
        }
    }
}
