import UIKit
import RxSwift

class AuthenticatorAuthFlowController: BaseFlowController {
    
    // MARK: - Private properties
    
    private let navigationController: NavigationControllerProtocol
    private let userDataManager: UserDataManagerProtocol
    private let keychainManager: KeychainManagerProtocol
    private let onAuthorized: (_ account: String) -> Void
    private let onCancelled: () -> Void
    
    private weak var rootScrene: UIViewController?
    private var completionRootScrene: UIViewController {
        return self.rootScrene ?? UIViewController()
    }
    private let disposeBag = DisposeBag()
    
    // MARK: -
    
    init(
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        rootNavigation: RootNavigationProtocol,
        navigationController: NavigationControllerProtocol,
        userDataManager: UserDataManagerProtocol,
        keychainManager: KeychainManagerProtocol,
        onAuthorized: @escaping (_ account: String) -> Void,
        onCancelled: @escaping () -> Void
        ) {
        
        self.navigationController = navigationController
        self.userDataManager = userDataManager
        self.keychainManager = keychainManager
        self.onAuthorized = onAuthorized
        self.onCancelled = onCancelled
        
        super.init(
            appController: appController,
            flowControllerStack: flowControllerStack,
            rootNavigation: rootNavigation
        )
    }
    
    // MARK: - Public
    
    public func run(showRootScreene: @escaping(UIViewController) -> Void) {
        let vc = self.setupAuthenticatorAuthScene()
        self.rootScrene = vc
        
        vc.navigationItem.title = Localized(.authenticator)
        let backButton = UIBarButtonItem(title: Localized(.back), style: .plain, target: nil, action: nil)
        backButton.title = Localized(.back)
        backButton
            .rx
            .tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.onCancelled()
            })
            .disposed(by: self.disposeBag)
        
        vc.navigationItem.setLeftBarButton(backButton, animated: false)
        showRootScreene(vc)
    }
    
    // MARK: - Private
    
    private func setupAuthenticatorAuthScene() -> UIViewController {
        let vc = AuthenticatorAuth.ViewController()
        
        let qrCodeGenerator = QRCodeGenerator()
        
        let sceneModel = AuthenticatorAuth.Model.SceneModel(
            publicKey: nil,
            qrSize: .zero
        )
        let authRequestBuilder = AuthenticatorAuth.AuthRequestBuilder(
            apiConfiguration: self.flowControllerStack.apiConfigurationModel
        )
        let authWorker = AuthenticatorAuth.AuthRequestWorker(
            accountApi: self.flowControllerStack.api.accountsApi,
            keyServerApi: self.flowControllerStack.keyServerApi,
            generalApi: self.flowControllerStack.api.generalApi,
            apiConfigurationModel: self.flowControllerStack.apiConfigurationModel,
            keychainManager: self.keychainManager,
            userDataManager: self.userDataManager
        )
        
        let authAppAvailibilityChecker = AuthenticatorAuth.AuthAppAvailibilityChecker()
        let authRequestKeyFetcher = AuthenticatorAuth.AuthRequestKeyFecther()
        let downloadUrlFetcher = AuthenticatorAuth.DownloadUrlFethcer(
            apiConfiguration: self.flowControllerStack.apiConfigurationModel
        )
        let routing = AuthenticatorAuth.Routing(
            openUrl: { (url) in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
        },
            showError: { [weak self] (message) in
                self?.navigationController.showErrorMessage(
                    message,
                    completion: self?.onCancelled
                )
            },
            onSuccessfulSignIn: { [weak self] (account) in
                self?.onAuthorized(account)
        })
        
        AuthenticatorAuth.Configurator.configure(
            viewController: vc,
            appController: self.appController,
            sceneModel: sceneModel,
            authRequestWorker: authWorker,
            authAppAvailibilityChecker: authAppAvailibilityChecker,
            authRequestKeyFetcher: authRequestKeyFetcher,
            qrCodeGenerator: qrCodeGenerator,
            authRequestBuilder: authRequestBuilder,
            downloadUrlFetcher: downloadUrlFetcher,
            routing: routing
        )
        
        return vc
    }
}
