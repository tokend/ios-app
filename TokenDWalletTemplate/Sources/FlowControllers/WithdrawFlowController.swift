import UIKit

class WithdrawFlowController: BaseSignedInFlowController {
    
    // MARK: - Private properties
    
    private let navigationController: NavigationControllerProtocol = NavigationController()
    
    private var onShowWalletScreen: (() -> Void)?
    
    // MARK: - Public
    
    func run(
        showRootScreen: ((_ vc: UIViewController) -> Void)?,
        onShowWalletScreen: @escaping () -> Void
        ) {
        self.startFromWithdrawScreen(showRootScreen: showRootScreen)
        self.onShowWalletScreen = onShowWalletScreen
    }
    
    // MARK: - Private
    
    private func startFromWithdrawScreen(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        let viewController = self.setupWithdrawScreen()
        
        viewController.navigationItem.title = Localized(.withdraw)
        
        self.navigationController.setViewControllers([viewController], animated: false)
        
        if let showRoot = showRootScreen {
            showRoot(self.navigationController.getViewController())
        } else {
            self.rootNavigation.setRootContent(self.navigationController, transition: .fade, animated: false)
        }
    }
    
    private func setupWithdrawScreen() -> SendPayment.ViewController {
        let vc = SendPayment.ViewController()
        
        let balanceDetailsLoader = SendPayment.BalanceDetailsLoaderWorker(
            balancesRepo: self.reposController.balancesRepo
        )
        
        let amountFormatter = TokenDetailsScene.AmountFormatter()
        
        let recipientAddressResolver = SendPayment.WithdrawRecipientAddressResolver(
            generalApi: self.flowControllerStack.api.generalApi
        )
        
        let feeLoader = FeeLoader(
            generalApi: self.flowControllerStack.api.generalApi
        )
        let feeLoaderWorker = SendPayment.FeeLoaderWorker(
            feeLoader: feeLoader
        )
        
        let viewConfig = SendPayment.Model.ViewConfig.sendWithdraw()
        
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
            onSendAction: nil,
            onSendWithdraw: { [weak self] (sendModel) in
                self?.showWithdrawConfirmationScreen(sendWithdrawModel: sendModel)
        })
        
        SendPayment.Configurator.configure(
            viewController: vc,
            senderAccountId: self.userDataProvider.walletData.accountId,
            selectedBalanceId: nil,
            balanceDetailsLoader: balanceDetailsLoader,
            amountFormatter: amountFormatter,
            recipientAddressResolver: recipientAddressResolver,
            feeLoader: feeLoaderWorker,
            feeType: SendPayment.Model.FeeType.withdraw,
            operation: SendPayment.Model.Operation.handleWithdraw,
            viewConfig: viewConfig,
            routing: routing
        )
        
        return vc
    }
    
    private func showWithdrawConfirmationScreen(sendWithdrawModel: SendPayment.Model.SendWithdrawModel) {
        let vc = self.setupWithdrawConfirmationScreen(sendWithdrawModel: sendWithdrawModel)
        
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func setupWithdrawConfirmationScreen(
        sendWithdrawModel: SendPayment.Model.SendWithdrawModel
        ) -> ConfirmationScene.ViewController {
        
        let vc = ConfirmationScene.ViewController()
        
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
        
        let senderFee = ConfirmationScene.Model.FeeModel(
            asset: sendWithdrawModel.senderFee.asset,
            fixed: sendWithdrawModel.senderFee.fixed,
            percent: sendWithdrawModel.senderFee.percent
        )
        
        let withdrawModel = ConfirmationScene.Model.WithdrawModel(
            senderBalanceId: sendWithdrawModel.senderBalanceId,
            asset: sendWithdrawModel.asset,
            amount: sendWithdrawModel.amount,
            recipientAddress: sendWithdrawModel.recipientAddress,
            senderFee: senderFee
        )
        
        let amountFormatter = ConfirmationScene.AmountFormatter()
        let percentFormatter = ConfirmationScene.PercentFormatter()
        let amountConverter = AmountConverter()
        
        let sectionsProvider = ConfirmationScene.WithdrawConfirmationSectionsProvider(
            withdrawModel: withdrawModel,
            transactionSender: self.managersController.transactionSender,
            networkInfoFetcher: self.reposController.networkInfoRepo,
            amountFormatter: amountFormatter,
            userDataProvider: self.userDataProvider,
            amountConverter: amountConverter,
            percentFormatter: percentFormatter
        )
        
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
