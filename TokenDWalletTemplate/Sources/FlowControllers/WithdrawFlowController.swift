import UIKit
import RxSwift

class WithdrawFlowController: BaseSignedInFlowController {
    
    // MARK: - Private properties
    
    private var navigationController: NavigationControllerProtocol?
    private let selectedBalanceId: String?
    private let disposeBag: DisposeBag = DisposeBag()
    
    private var onShowMovements: (() -> Void)?
    
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
        onShowMovements: (() -> Void)?
        ) {
        
        self.startFromWithdrawAmountScreen(showRootScreen: showRootScreen)
        self.onShowMovements = onShowMovements
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
        let feeOverviewer = SendPaymentAmount.FeeOverviewer(
            generalApi: self.flowControllerStack.api.generalApi,
            accountId: self.userDataProvider.walletData.accountId
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
            onPresentPicker: { [weak self] (assets, onSelected) in
                self?.showBalancePicker(
                    targetAssets: assets,
                    onSelected: onSelected
                )
            },
            onSendAction: nil,
            onShowWithdrawDestination: { [weak self] (sendModel) in
                self?.showWithdrawDestinationScreen(withdrawAmountModel: sendModel)
            },
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
                self?.onShowMovements?()
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
    
    private func showFees(asset: String, feeType: Int32) {
        let vc = self.setupFees(asset: asset, feeType: feeType)
        
        vc.navigationItem.title = Localized(.fees)
        self.navigationController?.pushViewController(vc, animated: true)
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
        let feeDataFormatter = Fees.FeeDataFormatter(
            amountFormatter: amountFormatter
        )
        
        let routing = Fees.Routing(
            showProgress: { [weak self] in
                self?.navigationController?.showProgress()
            },
            hideProgress: { [weak self] in
                self?.navigationController?.hideProgress()
            },
            showMessage: { [weak self] (message) in
                self?.navigationController?.showErrorMessage(message, completion: nil)
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
        
        navController.present(
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
