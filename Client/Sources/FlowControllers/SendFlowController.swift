import Foundation
import TokenDSDK

class SendFlowController: BaseSignedInFlowController {
    
    // MARK: - Private properties
    
    private lazy var rootViewController: SendAssetScene.ViewController = initSendAsset()
    
    private let navigationController: NavigationControllerProtocol
    private let recipientAddressProcessor: RecipientAddressProcessorProtocol
    private lazy var feesProcessor: FeesProcessorProtocol = FeesProcessor(
        originalAccountId: self.userDataProvider.walletData.accountId,
        feesApi: self.flowControllerStack.apiV3.feesApi
    )
    private let sendPaymentStorage: SendPaymentStorageProtocol
    private lazy var paymentSender: PaymentSenderProtocol = initPaymentSender()

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
        self.sendPaymentStorage = SendPaymentStorage(balanceId: balanceId)
        
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
                                
                                self?.sendPaymentStorage.updatePaymentModel(
                                    sourceBalanceId: nil,
                                    assetCode: nil,
                                    destinationAccountId: recipientAddress.accountId,
                                    recipientEmail: recipientAddress.email,
                                    amount: nil,
                                    senderFee: nil,
                                    recipientFee: nil,
                                    isPayingFeeForRecipient: nil,
                                    description: nil
                                )
                                
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
        
        guard let infoProvider = try? initInfoProvider(
                recipientAccountId: recipientAccountId,
                recipientEmail: recipientEmail
        )
        else {
            self.navigationController.showErrorMessage(
                Localized(.error_unknown),
                completion: nil
            )
            return
        }
        
        let vc: SendAmountScene.ViewController = initSendAmount(
            recipientAccountId: recipientAccountId,
            infoProvider: infoProvider
        )
        
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    func initSendAmount(
        recipientAccountId: String,
        infoProvider: SendAmountScene.InfoProviderProtocol
    ) -> SendAmountScene.ViewController {
    
        let vc: SendAmountScene.ViewController = .init()
        
        let routing: SendAmountScene.Routing = .init(
            onContinue: { [weak self] (amount, assetCode, isPayingFeeForRecipient, description) in
                
                self?.sendPaymentStorage.updatePaymentModel(
                    sourceBalanceId: nil,
                    assetCode: assetCode,
                    destinationAccountId: nil,
                    recipientEmail: nil,
                    amount: amount,
                    senderFee: self?.feesProcessor.fees?.senderFee,
                    recipientFee: self?.feesProcessor.fees?.recipientFee,
                    isPayingFeeForRecipient: isPayingFeeForRecipient,
                    description: description
                )
                
                self?.showSendConfirmation()
            }
        )
        
        let feesProvider: SendAmountScene.FeesProviderProtocol = SendAmountScene.FeesProvider(
            feesProcessor: self.feesProcessor,
            recipientAccountId: recipientAccountId
        )
        
        SendAmountScene.Configurator.configure(
            viewController: vc,
            routing: routing,
            infoProvider: infoProvider,
            feesProvider: feesProvider
        )
        
        return vc
    }
    
    func showSendConfirmation() {
        
        guard let paymentModel = try? sendPaymentStorage.buildPaymentModel()
        else {
            self.navigationController.showErrorMessage(
                Localized(.error_unknown),
                completion: nil
            )
            return
        }
        
        let vc: SendConfirmationScene.ViewController = initSendConfirmation(
            paymentModel: paymentModel
        )
        navigationController.pushViewController(vc, animated: true)
    }
    
    func initSendConfirmation(
        paymentModel: SendPaymentStorageProtocolPaymentModel
    ) -> SendConfirmationScene.ViewController {
        
        let vc: SendConfirmationScene.ViewController = .init()
        
        let routing: SendConfirmationScene.Routing = .init(
            onConfirmation: { [weak self] in
                self?.performSend(paymentModel: paymentModel)
            }
        )
        
        let paymentProvider: SendConfirmationScene.PaymentProviderProtocol = SendConfirmationScene.PaymentProvider(
            paymentModel: paymentModel
        )
        
        SendConfirmationScene.Configurator.configure(
            viewController: vc,
            routing: routing,
            paymentProvider: paymentProvider
        )
        
        return vc
    }
    
    func performSend(paymentModel: SendPaymentStorageProtocolPaymentModel) {
        
        self.paymentSender.sendPayment(
            sourceBalanceId: paymentModel.sourceBalanceId,
            destinationAccountId: paymentModel.destinationAccountId,
            amount: paymentModel.amount,
            senderFee: paymentModel.senderFee,
            recipientFee: paymentModel.recipientFee,
            isPayingFeeForRecipient: paymentModel.isPayingFeeForRecipient,
            description: paymentModel.description ?? "",
            reference: paymentModel.reference,
            completion: { [weak self] (result) in
                
                switch result {
                
                case .success:
                    self?.reposController.balancesRepo.reloadBalancesDetails()
                    self?.reposController.movementsRepo.loadAllMovements(completion: nil)
                    self?.onClose()
                    
                case .failure:
                    self?.navigationController.showErrorMessage(
                        Localized(.error_unknown),
                        completion: nil
                    )
                }
            }
        )
    }
    
    func initInfoProvider(
        recipientAccountId: String,
        recipientEmail: String?
    ) throws -> SendAmountScene.InfoProviderProtocol {
        
        return try SendAmountScene.InfoProviderProvider(
            recipientAccountId: recipientAccountId,
            recipientEmail: recipientEmail,
            balancesRepo: reposController.balancesRepo,
            selectedBalanceId: self.sendPaymentStorage.payment.sourceBalanceId,
            onFailedToFetchSelectedBalance: { [weak self] (_) in
                
                self?.navigationController.showErrorMessage(
                    Localized(.send_error_failed_to_fetch_your_balance),
                    completion: { [weak self] in
                        self?.onClose()
                    }
                )
            }
        )
    }
    
    func initPaymentSender() -> PaymentSenderProtocol {
        return PaymentSender(
            networkInfoRepo: self.reposController.networkInfoRepo,
            transactionCreator: self.managersController.transactionCreator,
            transactionSender: self.managersController.transactionSender,
            amountConverter: self.managersController.amountConverter,
            originalAccountId: self.userDataProvider.walletData.accountId
        )
    }
}
