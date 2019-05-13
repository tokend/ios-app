import UIKit

class WithdrawFlowController: BaseSignedInFlowController {
    
    // MARK: - Private properties
    
    private var navigationController: NavigationControllerProtocol?
    private let selectedBalanceId: String?
    
    private var onShowWalletScreen: ((_ selectedBalanceId: String?) -> Void)?
    
    // MARK: -
    
    init(
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        reposController: ReposController,
        managersController: ManagersController,
        userDataProvider: UserDataProviderProtocol,
        keychainDataProvider: KeychainDataProviderProtocol,
        rootNavigation: RootNavigationProtocol,
        navigationController: NavigationControllerProtocol?,
        selectedBalanceId: String? = nil
        ) {
        
        self.selectedBalanceId = selectedBalanceId
        self.navigationController = navigationController
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
        
        self.startFromWithdrawAmountScreen(showRootScreen: showRootScreen)
        self.onShowWalletScreen = onShowWalletScreen
    }
    
    // MARK: - Private
    
    private func startFromWithdrawAmountScreen(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        let viewController = self.setupWithdrawAmountScreen()
        
        viewController.navigationItem.title = Localized(.withdraw_amount)
        if self.navigationController == nil {
            let navigationController = NavigationController()
            self.navigationController = navigationController
            self.navigationController?.setViewControllers([viewController], animated: false)
            
            if let showRoot = showRootScreen {
                showRoot(navigationController.getViewController())
            } else {
                self.rootNavigation.setRootContent(navigationController, transition: .fade, animated: false)
            }
        } else {
            if let showRoot = showRootScreen {
                showRoot(viewController)
            }
        }
    }
    
    private func setupWithdrawAmountScreen() -> SendPaymentAmount.ViewController {
        let vc = SendPaymentAmount.ViewController()
        
        let balanceDetailsLoader = SendPaymentAmount.BalanceDetailsLoaderWorker(
            balancesRepo: self.reposController.balancesRepo,
            assetsRepo: self.reposController.assetsRepo,
            operation: .handleWithdraw
        )
        
        let amountFormatter = SendPaymentAmount.AmountFormatter()
        
        let feeLoader = FeeLoader(
            generalApi: self.flowControllerStack.api.generalApi
        )
        let feeLoaderWorker = SendPaymentAmount.FeeLoaderWorker(
            feeLoader: feeLoader
        )
        
        let sceneModel = SendPaymentAmount.Model.SceneModel(
            feeType: .withdraw,
            operation: .handleWithdraw
        )
        
        let viewConfig = SendPaymentAmount.Model.ViewConfig.withdrawViewConfig()
        
        let routing = SendPaymentAmount.Routing(
            onShowProgress: { [weak self] in
                self?.navigationController?.showProgress()
            },
            onHideProgress: { [weak self] in
                self?.navigationController?.hideProgress()
            },
            onShowError: { [weak self] (errorMessage) in
                self?.navigationController?.showErrorMessage(errorMessage, completion: nil)
            },
            onPresentPicker: { [weak self] (title, options, onSelected) in
                guard let present = self?.navigationController?.getPresentViewControllerClosure() else {
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
            onShowWithdrawDestination: { [weak self] (sendModel) in
                self?.showWithdrawDestinationScreen(withdrawAmountModel: sendModel)
            }, onShowMessage: { [weak self] (message) in
                guard let present = self?.navigationController?.getPresentViewControllerClosure() else {
                    return
                }
                self?.showSuccessMessage(
                    title: message,
                    message: nil,
                    completion: nil,
                    presentViewController: present
                )
            })
        
        SendPaymentAmount.Configurator.configure(
            viewController: vc,
            senderAccountId: self.userDataProvider.walletData.accountId,
            selectedBalanceId: self.selectedBalanceId,
            sceneModel: sceneModel,
            balanceDetailsLoader: balanceDetailsLoader,
            amountFormatter: amountFormatter,
            feeLoader: feeLoaderWorker,
            viewConfig: viewConfig,
            routing: routing
        )
        
        return vc
    }
    
    private func showWithdrawDestinationScreen(
        withdrawAmountModel: SendPaymentAmount.Model.SendWithdrawModel
        ) {
        
        let vc = self.setupWithdrawDestinationScreen(withdrawAmountModel: withdrawAmountModel)
        
        vc.navigationItem.title = Localized(.withdraw_destination)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func setupWithdrawDestinationScreen(
        withdrawAmountModel: SendPaymentAmount.Model.SendWithdrawModel
        ) -> SendPaymentDestination.ViewController {
        
        let vc = SendPaymentDestination.ViewController()
        let viewConfig = SendPaymentDestination.Model.ViewConfig.sendWithdraw()
        
        let sceneModel = SendPaymentDestination.Model.SceneModel(
            feeType: .withdraw,
            operation: .handleWithdraw
        )
        sceneModel.amount = withdrawAmountModel.amount
        sceneModel.selectedBalance = withdrawAmountModel.senderBalance
        sceneModel.senderFee = withdrawAmountModel.senderFee
        
        let routing = SendPaymentDestination.Routing(
            onSelectContactEmail: { [weak self] (completion) in
                self?.presentContactEmailPicker(
                    completion: completion,
                    presentViewController: { [weak self] (vc, animated, completion) in
                        self?.navigationController?.present(vc, animated: animated, completion: completion)
                })
            },
            onPresentQRCodeReader: { [weak self] (completion) in
                self?.presentQRCodeReader(completion: completion)
            }, showWithdrawConformation: { [weak self] (model) in
                self?.showWithdrawConfirmationScreen(sendWithdrawModel: model)
            }, showSendAmount: { _ in
                
            }, showProgress: { [weak self] in
                self?.navigationController?.showProgress()
            }, hideProgress: { [weak self] in
                self?.navigationController?.hideProgress()
            }, showError: { [weak self] (message) in
                self?.navigationController?.showErrorMessage(message, completion: nil)
        })
        
        let recipientAddressResolver = SendPaymentDestination.WithdrawRecipientAddressResolver(
            generalApi: self.flowControllerStack.api.generalApi
        )
        
        let contactsFetcher = SendPaymentDestination.ContactsFetcher()
        
        SendPaymentDestination.Configurator.configure(
            viewController: vc,
            recipientAddressResolver: recipientAddressResolver,
            contactsFetcher: contactsFetcher,
            sceneModel: sceneModel,
            viewConfig: viewConfig,
            routing: routing
        )
        
        return vc
    }
    
    private func showWithdrawConfirmationScreen(sendWithdrawModel: SendPaymentDestination.Model.SendWithdrawModel) {
        let vc = self.setupWithdrawConfirmationScreen(sendWithdrawModel: sendWithdrawModel)
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func setupWithdrawConfirmationScreen(
        sendWithdrawModel: SendPaymentDestination.Model.SendWithdrawModel
        ) -> ConfirmationScene.ViewController {
        
        let vc = ConfirmationScene.ViewController()
        
        let routing = ConfirmationScene.Routing(
            onShowProgress: { [weak self] in
                self?.navigationController?.showProgress()
            },
            onHideProgress: { [weak self] in
                self?.navigationController?.hideProgress()
            },
            onShowError: { [weak self] (errorMessage) in
                self?.navigationController?.showErrorMessage(errorMessage, completion: nil)
            },
            onConfirmationSucceeded: { [weak self] in
                self?.onShowWalletScreen?(sendWithdrawModel.senderBalanceId)
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
    
    private func presentQRCodeReader(completion: @escaping SendPaymentDestination.QRCodeReaderCompletion) {
        self.runQRCodeReaderFlow(
            presentingViewController: self.navigationController?.getViewController() ?? UIViewController(),
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
