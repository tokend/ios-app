import UIKit
import RxSwift

class SendPaymentFlowController: BaseSignedInFlowController {
    
    // MARK: - Private properties
    
    private let navigationController: NavigationControllerProtocol
    private let selectedBalanceId: String?
    private let disposeBag: DisposeBag = DisposeBag()
    
    private var onShowMovements: (() -> Void)?
    
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
        onShowMovements: (() -> Void)?
        ) {
        
        self.onShowMovements = onShowMovements
        self.startFromDestinationScreen(showRootScreen: showRootScreen)
    }
    
    // MARK: - Private
    
    private func startFromDestinationScreen(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        let viewController = self.setupSendDestinationScreen()
        
        viewController.navigationItem.title = Localized(.payment_destination)
        
        if let showRoot = showRootScreen {
            showRoot(viewController)
        } else {
            self.rootNavigation.setRootContent(self.navigationController, transition: .fade, animated: false)
        }
    }
    
    private func showSendPaymentAmountScene(
        destination: SendPaymentDestination.Model.SendDestinationModel
        ) {
        
        let vc = self.setupSendAmountScreen(destination: destination)
        
        vc.navigationItem.title = Localized(.payment_amount)
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func setupSendAmountScreen(
        destination: SendPaymentDestination.Model.SendDestinationModel
        ) -> SendPaymentAmount.ViewController {
        
        let vc = SendPaymentAmount.ViewController()
        
        let balanceDetailsLoader = SendPaymentAmount.BalanceDetailsLoaderWorker(
            balancesRepo: self.reposController.balancesRepo,
            assetsRepo: self.reposController.assetsRepo,
            operation: .handleSend
        )
        
        let amountFormatter = SendPaymentAmount.AmountFormatter()
        
        let feeLoader = FeeLoader(
            generalApi: self.flowControllerStack.api.generalApi
        )
        let feeLoaderWorker = SendPaymentAmount.FeeLoaderWorker(
            feeLoader: feeLoader
        )
        let feeOverviewer = SendPaymentAmount.FeeOverviewer(
            generalApi: self.flowControllerStack.api.generalApi,
            accountId: self.userDataProvider.walletData.accountId
        )
        
        let sceneModel = SendPaymentAmount.Model.SceneModel(
            feeType: .payment,
            operation: .handleSend,
            recipientAddress: destination.recipientNickname
        )
        sceneModel.resolvedRecipientId = destination.recipientAccountId
        
        let viewConfig = SendPaymentAmount.Model.ViewConfig.sendPaymentViewConfig()
        
        let routing = SendPaymentAmount.Routing(
            onShowProgress: { [weak self] in
                self?.navigationController.showProgress()
            },
            onHideProgress: { [weak self] in
                self?.navigationController.hideProgress()
            },
            onShowError: { [weak self] (errorMessage) in
                self?.navigationController.showErrorMessage(errorMessage, completion: nil)
            },
            onPresentPicker: { [weak self] (assets, onSelected) in
                self?.showBalancePicker(
                    targetAssets: assets,
                    onSelected: onSelected
                )
            },
            onSendAction: { [weak self] (sendModel) in
                self?.showPaymentConfirmationScreen(sendPaymentModel: sendModel)
            },
            onShowWithdrawDestination: nil,
            showFeesOverview: { [weak self] (asset, feeType) in
                self?.showFees(asset: asset, feeType: feeType)
        })
        
        SendPaymentAmount.Configurator.configure(
            viewController: vc,
            senderAccountId: self.userDataProvider.walletData.accountId,
            selectedBalanceId: self.selectedBalanceId,
            sceneModel: sceneModel,
            balanceDetailsLoader: balanceDetailsLoader,
            amountFormatter: amountFormatter,
            feeLoader: feeLoaderWorker,
            feeOverviewer: feeOverviewer,
            viewConfig: viewConfig,
            routing: routing
        )
        
        return vc
    }
    
    private func setupSendDestinationScreen() -> SendPaymentDestination.ViewController {
        let vc = SendPaymentDestination.ViewController()
        let viewConfig = SendPaymentDestination.Model.ViewConfig.sendPayment()
        let routing = SendPaymentDestination.Routing(
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
            showWithdrawConformation: { (_) in
                
        },
            showSendAmount: { [weak self] (destination) in
                self?.showSendPaymentAmountScene(destination: destination)
            },
            showProgress: { [weak self] in
                self?.navigationController.showProgress()
            },
            hideProgress: { [weak self] in
                self?.navigationController.hideProgress()
            },
            showError: { [weak self] (message) in
                self?.navigationController.showErrorMessage(message, completion: nil)
        })
        
        let recipientAddressResolver = SendPaymentDestination.RecipientAddressResolverWorker(
            generalApi: self.flowControllerStack.api.generalApi
        )
        
        let contactsFetcher = SendPaymentDestination.ContactsFetcher()
        
        let sceneModel = SendPaymentDestination.Model.SceneModel(
            feeType: .payment,
            operation: .handleSend
        )
        
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
    
    private func showPaymentConfirmationScreen(sendPaymentModel: SendPaymentAmount.Model.SendPaymentModel) {
        let vc = self.setupPaymentConfirmationScreen(sendPaymentModel: sendPaymentModel)
        
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func setupPaymentConfirmationScreen(
        sendPaymentModel: SendPaymentAmount.Model.SendPaymentModel
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
            description: sendPaymentModel.description,
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
                self?.onShowMovements?()
        })
        
        ConfirmationScene.Configurator.configure(
            viewController: vc,
            sectionsProvider: sectionsProvider,
            routing: routing
        )
        
        vc.navigationItem.title = Localized(.confirmation)
        
        return vc
    }
    
    private func showFees(asset: String, feeType: Int32) {
        let vc = self.setupFees(asset: asset, feeType: feeType)
        
        vc.navigationItem.title = Localized(.fees)
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func setupFees(asset: String, feeType: Int32) -> UIViewController {
        let vc = Fees.ViewController()
        let feesOverviewProvider = Fees.FeesProvider(
            generalApi: self.flowControllerStack.api.generalApi,
            accountId: self.userDataProvider.walletData.accountId
        )
        
        var target: Fees.Model.Target?
        if let systemFeeType = Fees.Model.OperationType(rawValue: feeType) {
            target = Fees.Model.Target(asset: asset, feeType: systemFeeType)
        }
        
        let sceneModel = Fees.Model.SceneModel(
            fees: [],
            selectedAsset: nil,
            target: target
        )
        
        let amountFormatter = Fees.AmountFormatter()
        let feeDataFormatter = Fees.FeeDataFormatter(amountFormatter: amountFormatter)
        
        let routing = Fees.Routing(
            showProgress: { [weak self] in
                self?.navigationController.showProgress()
            },
            hideProgress: { [weak self] in
                self?.navigationController.hideProgress()
            },
            showMessage: { [weak self] (message) in
                self?.navigationController.showErrorMessage(message, completion: nil)
        })
        
        Fees.Configurator.configure(
            viewController: vc,
            feesOverviewProvider: feesOverviewProvider,
            sceneModel: sceneModel,
            feeDataFormatter: feeDataFormatter,
            routing: routing
        )
        
        return vc
    }
    
    // MARK: -
    
    private func presentQRCodeReader(completion: @escaping SendPaymentDestination.QRCodeReaderCompletion) {
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
    
    private func showBalancePicker(
        targetAssets: [String],
        onSelected: @escaping ((String) -> Void)
        ) {
        
        let navController = NavigationController()
        
        let vc = self.setupBalancePicker(
            targetAssets: targetAssets,
            onSelected: onSelected
        )
        vc.navigationItem.title = Localized(.choose_asset)
        let closeBarItem = UIBarButtonItem(
            title: Localized(.back),
            style: .plain,
            target: nil,
            action: nil
        )
        closeBarItem
            .rx
            .tap
            .asDriver()
            .drive(onNext: { _ in
                navController
                    .getViewController()
                    .dismiss(animated: true, completion: nil)
            })
            .disposed(by: self.disposeBag)
        
        vc.navigationItem.leftBarButtonItem = closeBarItem
        navController.setViewControllers([vc], animated: false)
        
        self.navigationController.present(
            navController.getViewController(),
            animated: true,
            completion: nil
        )
    }
    
    private func setupBalancePicker(
        targetAssets: [String],
        onSelected: @escaping ((String) -> Void)
        ) -> UIViewController {
        
        let vc = BalancePicker.ViewController()
        let imageUtility = ImagesUtility(
            storageUrl: self.flowControllerStack.apiConfigurationModel.storageEndpoint
        )
        let balancesFetcher = BalancePicker.BalancesFetcher(
            balancesRepo: self.reposController.balancesRepo,
            assetsRepo: self.reposController.assetsRepo,
            imagesUtility: imageUtility,
            targetAssets: targetAssets
        )
        let sceneModel = BalancePicker.Model.SceneModel(
            balances: [],
            filter: nil
        )
        let amountFormatter = BalancePicker.AmountFormatter()
        let routing = BalancePicker.Routing(
            onBalancePicked: { (balanceId) in
                onSelected(balanceId)
        })
        
        BalancePicker.Configurator.configure(
            viewController: vc,
            balancesFetcher: balancesFetcher,
            sceneModel: sceneModel,
            amountFormatter: amountFormatter,
            routing: routing
        )
        return vc
    }
}
