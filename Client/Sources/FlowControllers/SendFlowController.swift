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
            recipientAddress: recipientEmail ?? recipientAccountId,
            selectedBalanceProvider: selectedBalanceProvider,
            feesProvider: feesProvider
        )
        
        return vc
    }
    
    func showSendConfirmation() {
        
        guard let recipientAccountId = sendPaymentStorage.payment.destinationAccountId,
              let amount = sendPaymentStorage.payment.amount,
              let assetCode = sendPaymentStorage.payment.assetCode,
              let senderFee = sendPaymentStorage.payment.senderFee,
              let recipientFee = sendPaymentStorage.payment.recipientFee,
              let isPayingFeeForRecipient = sendPaymentStorage.payment.isPayingFeeForRecipient
        else {
            self.navigationController.showErrorMessage(
                Localized(.error_unknown),
                completion: nil
            )
            return
        }
        
        let fee: Decimal
        if isPayingFeeForRecipient {
            fee = senderFee.calculatedPercent + senderFee.fixed + recipientFee.calculatedPercent + recipientFee.fixed
        } else {
            fee = senderFee.calculatedPercent + senderFee.fixed
        }
        
        let paymentProvider: SendConfirmationScene.PaymentProviderProtocol = SendConfirmationScene.PaymentProvider(
            recipientAccountId: recipientAccountId,
            recipientEmail: sendPaymentStorage.payment.recipientEmail,
            amount: amount,
            assetCode: assetCode,
            fee: fee,
            description: sendPaymentStorage.payment.description
        )
        
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
                self?.performSend()
            }
        )
        
        SendConfirmationScene.Configurator.configure(
            viewController: vc,
            routing: routing,
            paymentProvider: paymentProvider
        )
        
        return vc
    }
    
    func performSend() {
        
        guard let destinationAccountId = sendPaymentStorage.payment.destinationAccountId,
              let amount = sendPaymentStorage.payment.amount,
              let senderFee = sendPaymentStorage.payment.senderFee,
              let recipientFee = sendPaymentStorage.payment.recipientFee,
              let isPayingFeeForRecipient = sendPaymentStorage.payment.isPayingFeeForRecipient
        else {
            self.navigationController.showErrorMessage(
                Localized(.error_unknown),
                completion: nil
            )
            return
        }
        
        self.paymentSender.sendPayment(
            sourceBalanceId: sendPaymentStorage.payment.sourceBalanceId,
            destinationAccountId: destinationAccountId,
            amount: amount,
            senderFee: senderFee,
            recipientFee: recipientFee,
            isPayingFeeForRecipient: isPayingFeeForRecipient,
            description: sendPaymentStorage.payment.description ?? "",
            reference: sendPaymentStorage.payment.reference,
            completion: { [weak self] (result) in
                
                switch result {
                
                case .success:
                    // FIXME: - reload balances repo
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
    
    func initSelectedBalanceProvider(
    ) throws -> SendAmountScene.SelectedBalanceProviderProtocol {
        
        return try SendAmountScene.SelectedBalanceProvider(
            balancesRepo: reposController.balancesRepo,
            selectedBalanceId: self.sendPaymentStorage.payment.sourceBalanceId,
            onFailedToFetchSelectedBalance: { [weak self] (_) in
                
                self?.navigationController.showErrorMessage(
                    // TODO: - Localize
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
