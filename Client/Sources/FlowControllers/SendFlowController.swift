import Foundation
import TokenDSDK

class SendFlowController: BaseSignedInFlowController {
    
    // MARK: - Private properties
    
    private lazy var rootViewController: SendAssetScene.ViewController = initSendAsset()
    
    private let navigationController: NavigationControllerProtocol
    private let recipientAddressProcessor: RecipientAddressProcessorProtocol
    fileprivate let balanceId: String

    private let onClose: () -> Void
    
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
        balanceId: String,
        onClose: @escaping () -> Void
    ) {

        self.navigationController = navigationController
        self.balanceId = balanceId
        
        self.onClose = onClose
        
        recipientAddressProcessor = RecipientAddressProcessor(
            identitiesRepo: reposController.identitiesRepo,
            originalAccountId: userDataProvider.walletData.accountId
        )
        
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

private extension SendFlowController {
    
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
                
                self?.navigationController.showProgress()
                
                self?.recipientAddressProcessor.processRecipientAddress(
                    with: address,
                    completion: { [weak self] (result) in
                        
                        DispatchQueue.main.async {
                            
                            self?.navigationController.hideProgress()
                            
                            switch result {
                            
                            case .success(let recipientAddress):
                                self?.showSendAmount(
                                    recipientAccountId: recipientAddress.accountId,
                                    recipientEmail: recipientAddress.email
                                )
                                
                            case .failure(let error):
                                
                                switch error {
                                case let error as RecipientAddressProcessor.RecipientAddressProcessorError:
                                    
                                    switch error {
                                    
                                    case .noIdentity:
                                        self?.navigationController.showErrorMessage(
                                            Localized(.send_asset_no_identity_error),
                                            completion: nil
                                        )
                                        
                                    case .ownAccountId:
                                        self?.navigationController.showErrorMessage(
                                            Localized(.send_asset_own_account_error),
                                            completion: nil
                                        )
                                    }
                                    
                                default:
                                    self?.navigationController.showErrorMessage(
                                        Localized(.error_unknown),
                                        completion: nil
                                    )
                                }
                            }
                        }
                    }
                )
            }
        )
        
        SendAssetScene.Configurator.configure(
            viewController: vc,
            routing: routing,
            recipientProvider: recipientProvider
        )
        
        return vc
    }
    
    func showSendAmount(
        recipientAccountId: String,
        recipientEmail: String?
    ) {
        
        guard let selectedBalanceProvider = try? initSelectedBalanceProvider()
        else {
            self.navigationController.showErrorMessage(
                Localized(.error_unknown),
                completion: nil
            )
            return
        }
        
        let vc: SendAmountScene.ViewController = initSendAmount(
            recipientAccountId: recipientAccountId,
            recipientEmail: recipientEmail,
            selectedBalanceProvider: selectedBalanceProvider
        )
        
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    func initSendAmount(
        recipientAccountId: String,
        recipientEmail: String?,
        selectedBalanceProvider: SendAmountScene.SelectedBalanceProviderProtocol
    ) -> SendAmountScene.ViewController {
    
        let vc: SendAmountScene.ViewController = .init()
        
        let routing: SendAmountScene.Routing = .init(
            onContinue: { [weak self] (amount, assetCode, senderFee, description) in
                
                let paymentProvider: SendConfirmationScene.PaymentProviderProtocol = SendConfirmationScene.PaymentProvider(
                    recipientAccountId: recipientAccountId,
                    recipientEmail: recipientEmail,
                    amount: amount,
                    assetCode: assetCode,
                    fee: senderFee,
                    description: description
                )
                
                
                self?.showSendConfirmation(
                    paymentProvider: paymentProvider
                )
            }
        )
        
        let feesProcessor: SendAmountScene.FeesProcessorProtocol = SendAmountScene.FeesProcessor(
            originalAccountId: userDataProvider.walletData.accountId,
            recipientAccountId: recipientAccountId,
            feesApi: flowControllerStack.apiV3.feesApi
        )
        
        SendAmountScene.Configurator.configure(
            viewController: vc,
            routing: routing,
            recipientAddress: recipientEmail ?? recipientAccountId,
            selectedBalanceProvider: selectedBalanceProvider,
            feesProcessor: feesProcessor
        )
        
        return vc
    }
    
    func showSendConfirmation(
        paymentProvider: SendConfirmationScene.PaymentProviderProtocol
    ) {
        let vc: SendConfirmationScene.ViewController = initSendConfirmation(
            paymentProvider: paymentProvider
        )
        navigationController.pushViewController(vc, animated: true)
    }
    
    func initSendConfirmation(
        paymentProvider: SendConfirmationScene.PaymentProviderProtocol
    ) -> SendConfirmationScene.ViewController {
        
        let vc: SendConfirmationScene.ViewController = .init()
        
        let routing: SendConfirmationScene.Routing = .init(
            onConfirmation: { [weak self] in
                
            }
        )
        
        SendConfirmationScene.Configurator.configure(
            viewController: vc,
            routing: routing,
            paymentProvider: paymentProvider
        )
        
        return vc
    }
    
    func initSelectedBalanceProvider(
    ) throws -> SendAmountScene.SelectedBalanceProviderProtocol {
        
        return try SendAmountScene.SelectedBalanceProvider(
            balancesRepo: reposController.balancesRepo,
            selectedBalanceId: self.balanceId,
            onFailedToFetchSelectedBalance: { [weak self] (_) in
                
                self?.navigationController.showErrorMessage(
                    // TODO: - Localize
                    "Failed to fetch your balance",
                    completion: { [weak self] in
                        self?.onClose()
                    }
                )
            }
        )
    }
}
