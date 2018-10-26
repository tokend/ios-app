import UIKit

class SendPaymentFlowController: BaseSignedInFlowController {
    
    // MARK: - Private properties
    
    private let navigationController: NavigationControllerProtocol = NavigationController()
    
    private var onShowWalletScreen: (() -> Void)?
    
    // MARK: - Public
    
    func run(
        showRootScreen: ((_ vc: UIViewController) -> Void)?,
        onShowWalletScreen: @escaping () -> Void
        ) {
        self.onShowWalletScreen = onShowWalletScreen
        
        self.startFromSendScreen(showRootScreen: showRootScreen)
    }
    
    // MARK: - Private
    
    private func startFromSendScreen(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        let viewController = self.setupSendScreen()
        
        self.navigationController.navigationBar.titleTextAttributes = [
            NSAttributedStringKey.font: Theme.Fonts.navigationBarBoldFont,
            NSAttributedStringKey.foregroundColor: Theme.Colors.textOnMainColor
        ]
        
        viewController.navigationItem.title = "Send"
        
        self.navigationController.setViewControllers([viewController], animated: false)
        
        if let showRoot = showRootScreen {
            showRoot(self.navigationController.getViewController())
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
            onPresentQRCodeReader: { [weak self] (completion) in
                self?.presentQRCodeReader(completion: completion)
            },
            onPresentPicker: { [weak self] (title, options, onSelected) in
                self?.navigationController.showDialog(
                    title: title,
                    message: nil,
                    style: .actionSheet,
                    options: options,
                    onSelected: onSelected,
                    onCanceled: nil
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
            recipientFee: recipientFee
        )
        
        let sectionsProvider = ConfirmationScene.SendPaymentConfirmationSectionsProvider(
            sendPaymentModel: paymentModel,
            transactionSender: self.managersController.transactionSender,
            networkInfoFetcher: self.reposController.networkInfoRepo,
            amountFormatter: amountFormatter,
            userDataProvider: self.userDataProvider,
            amountConverter: amountConverter,
            percentFormatter: percentFormatter,
            amountPrecision: self.flowControllerStack.apiConfigurationModel.amountPrecision
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
                self?.onShowWalletScreen?()
        })
        
        ConfirmationScene.Configurator.configure(
            viewController: vc,
            sectionsProvider: sectionsProvider,
            routing: routing
        )
        
        vc.navigationItem.title = "Confirmation"
        
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
