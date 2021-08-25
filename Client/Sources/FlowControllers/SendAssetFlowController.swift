import Foundation
import TokenDSDK

class SendAssetFlowController: BaseSignedInFlowController {
    
    // MARK: - Private properties
    
    private lazy var rootViewController: SendAssetScene.ViewController = initSendAsset()

    private let navigationController: NavigationControllerProtocol
    fileprivate let assetId: String

    // MARK: -

    init(
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        reposController: ReposController,
        managersController: ManagersController,
        userDataProvider: UserDataProviderProtocol,
        keychainDataProvider: KeychainDataProviderProtocol,
        rootNavigation: RootNavigationProtocol,
        navigationController: NavigationControllerProtocol,
        assetId: String
    ) {

        self.navigationController = navigationController
        self.assetId = assetId
        
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
    
    // MARK: - Public

    public func run(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        showRootScreen?(rootViewController)
    }
}

// MARK: - Private methods

private extension SendAssetFlowController {
    
    func initSendAsset(
    ) -> SendAssetScene.ViewController {
        
        let vc: SendAssetScene.ViewController = .init()
        
        let recipientProvider = SendAssetScene.RecipientProvider()
        
        let routing: SendAssetScene.Routing = .init(
            onScanRecipient: { [weak self] in
                self?.runQRCodeReaderFlow(
                    presentingViewController: vc,
                    handler: { (result) in
                        
                        switch result {
                        
                        case .canceled:
                            break
                            
                        case .success(value: let value, _):
                            recipientProvider.setRecipientAddress(value: value)
                        }
                    }
                )
            },
            onContinue: { [weak self] (address) in
                print(.debug(message: address))
            }
        )
        
        SendAssetScene.Configurator.configure(
            viewController: vc,
            routing: routing,
            recipientProvider: recipientProvider
        )
        
        return vc
    }
}
