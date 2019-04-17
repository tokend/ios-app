import UIKit

class SendPaymentFlowController: BaseSignedInFlowController {
    
    // MARK: - Private properties
    
    private let navigationController: NavigationControllerProtocol
    private let selectedBalanceId: String?
    
    private var onShowWalletScreen: ((_ selectedBalanceId: String?) -> Void)?
    
    // MARK: -
    
    init(
        navigationController: NavigationControllerProtocol,
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        reposController: ReposController,
        managersController: ManagersController,
        userDataProvider: UserDataProviderProtocol,
        keychainDataProvider: KeychainDataProviderProtocol,
        rootNavigation: RootNavigationProtocol,
        selectedBalanceId: String?
        ) {
        
        self.navigationController = navigationController
        self.selectedBalanceId = selectedBalanceId
        
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
    
    func run(
        showRootScreen: ((_ vc: UIViewController) -> Void)?,
        onShowWalletScreen: @escaping (_ selectedBalanceId: String?) -> Void
        ) {
        self.onShowWalletScreen = onShowWalletScreen
        
        self.startFromSendScreen(showRootScreen: showRootScreen)
    }
    
    // MARK: - Private
    
    private func startFromSendScreen(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        let viewController = self.setupSendScreen()
        
        viewController.navigationItem.title = Localized(.send)
        
        if let showRoot = showRootScreen {
            showRoot(viewController)
        } else {
            self.rootNavigation.setRootContent(self.navigationController, transition: .fade, animated: false)
        }
    }
    
    private func setupSendScreen() -> SendPayment.ViewController {
        let vc = SendPayment.ViewController()
        
        let balanceDetailsLoader = SendPayment.BalanceDetailsLoaderWorker(
            balancesRepo: self.reposController.balancesRepo
        )
        
        let amountFormatter = TokenDetailsScene.AmountFormatter()
        
        let recipientAddressResolver = SendPayment.RecipientAddressResolverWorker(
            generalApi: self.flowControllerStack.api.generalApi
        )
        
        let feeLoader = FeeLoader(
            generalApi: self.flowControllerStack.api.generalApi
        )
        let feeLoaderWorker = SendPayment.FeeLoaderWorker(
            feeLoader: feeLoader
        )
        
        let viewConfig = SendPayment.Model.ViewConfig.sendPayment()
        
        let routing = SendPayment.Routing(
            onShowProgress: { [weak self] in
                self?.navigationController.showProgress()
            },
            onHideProgress: { [weak self] in
                self?.navigationController.hideProgress()
            },
            onShowError: { [weak self] (errorMessage) in
                self?.navigationController.showErrorMessage(errorMessage, completion: nil)
            },
            onSelectContactEmail: { [weak self] (completion) in
                self?.presentContactEmailPicker(
                    completion: completion,
                    presentViewController: { [weak self] (vc, animated, completion) in
                        self?.navigationController.present(vc, animated: animated, completion: completion)
                })
            },
            onPresentQRCodeReader: { [weak self] (completion) in
                self?.presentQRCodeReader(completion: completion)
            },
            onPresentPicker: { [weak self] (title, options, onSelected) in
                guard let present = self?.navigationController.getPresentViewControllerClosure() else {
                    return
                }
                
                self?.showDialog(
                    title: title,
                    message: nil,
                    style: .actionSheet,
                    options: options,
                    onSelected: onSelected,
                    onCanceled: nil,
                    presentViewController: present
                )
            },
            onSendAction: { [weak self] (sendModel) in
                self?.showPaymentConfirmationScreen(sendPaymentModel: sendModel)
            },
            onSendWithdraw: nil
        )
        
        SendPayment.Configurator.configure(
            viewController: vc,
            senderAccountId: self.userDataProvider.walletData.accountId,
            selectedBalanceId: self.selectedBalanceId,
            balanceDetailsLoader: balanceDetailsLoader,
            amountFormatter: amountFormatter,
            recipientAddressResolver: recipientAddressResolver,
            feeLoader: feeLoaderWorker,
            feeType: SendPayment.Model.FeeType.payment,
            operation: SendPayment.Model.Operation.handleSend,
            viewConfig: viewConfig,
            routing: routing
        )
        
        return vc
    }
    
    private func showPaymentConfirmationScreen(sendPaymentModel: SendPayment.Model.SendPaymentModel) {
        let vc = self.setupPaymentConfirmationScreen(sendPaymentModel: sendPaymentModel)
        
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func setupPaymentConfirmationScreen(
        sendPaymentModel: SendPayment.Model.SendPaymentModel
        ) -> ConfirmationScene.ViewController {
        
        let vc = ConfirmationScene.ViewController()
        
        let amountFormatter = ConfirmationScene.AmountFormatter()
        let percentFormatter = ConfirmationScene.PercentFormatter()
        let amountConverter = AmountConverter()
        
        let senderFee = ConfirmationScene.Model.FeeModel(
            asset: sendPaymentModel.senderFee.asset,
            fixed: sendPaymentModel.senderFee.fixed,
            percent: sendPaymentModel.senderFee.percent
        )
        
        let recipientFee = ConfirmationScene.Model.FeeModel(
            asset: sendPaymentModel.recipientFee.asset,
            fixed: sendPaymentModel.recipientFee.fixed,
            percent: sendPaymentModel.recipientFee.percent
        )
        
        let paymentModel = ConfirmationScene.Model.SendPaymentModel(
            senderBalanceId: sendPaymentModel.senderBalanceId,
            asset: sendPaymentModel.asset,
            amount: sendPaymentModel.amount,
            recipientNickname: sendPaymentModel.recipientNickname,
            recipientAccountId: sendPaymentModel.recipientAccountId,
            senderFee: senderFee,
            recipientFee: recipientFee,
            reference: sendPaymentModel.reference
        )
        
        let sectionsProvider = ConfirmationScene.SendPaymentConfirmationSectionsProvider(
            sendPaymentModel: paymentModel,
            transactionSender: self.managersController.transactionSender,
            networkInfoFetcher: self.reposController.networkInfoRepo,
            amountFormatter: amountFormatter,
            userDataProvider: self.userDataProvider,
            amountConverter: amountConverter,
            percentFormatter: percentFormatter
        )
        
        let routing = ConfirmationScene.Routing(
            onShowProgress: { [weak self] in
                self?.navigationController.showProgress()
            },
            onHideProgress: { [weak self] in
                self?.navigationController.hideProgress()
            },
            onShowError: { [weak self] (errorMessage) in
                self?.navigationController.showErrorMessage(errorMessage, completion: nil)
            },
            onConfirmationSucceeded: { [weak self] in
                self?.onShowWalletScreen?(sendPaymentModel.senderBalanceId)
        })
        
        ConfirmationScene.Configurator.configure(
            viewController: vc,
            sectionsProvider: sectionsProvider,
            routing: routing
        )
        
        vc.navigationItem.title = Localized(.confirmation)
        
        return vc
    }
    
    // MARK: -
    
    private func presentQRCodeReader(completion: @escaping SendPayment.QRCodeReaderCompletion) {
        self.runQRCodeReaderFlow(
            presentingViewController: self.navigationController.getViewController(),
            handler: { result in
                switch result {
                    
                case .canceled:
                    completion(.canceled)
                    
                case .success(let value, let metadataType):
                    completion(.success(value: value, metadataType: metadataType))
                }
        })
    }
}
