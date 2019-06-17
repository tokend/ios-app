import UIKit

class BaseSignedInFlowController: BaseFlowController {
    
    let reposController: ReposController
    let managersController: ManagersController
    let userDataProvider: UserDataProviderProtocol
    let keychainDataProvider: KeychainDataProviderProtocol
    
    init(
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        reposController: ReposController,
        managersController: ManagersController,
        userDataProvider: UserDataProviderProtocol,
        keychainDataProvider: KeychainDataProviderProtocol,
        rootNavigation: RootNavigationProtocol
        ) {
        
        self.reposController = reposController
        self.managersController = managersController
        self.userDataProvider = userDataProvider
        self.keychainDataProvider = keychainDataProvider
        super.init(
            appController: appController,
            flowControllerStack: flowControllerStack,
            rootNavigation: rootNavigation
        )
    }
    
    // MARK: - Public
    
    func showTransactionDetailsScreen(
        transactionsProvider: TransactionDetails.TransactionsProviderProtocol,
        navigationController: NavigationControllerProtocol,
        transactionId: UInt64,
        balanceId: String,
        completion: (() -> Void)? = nil
        ) {
        
        let emailFetcher = TransactionDetails.EmailFetcher(
            generalApi: self.flowControllerStack.api.generalApi
        )
        let sectionsProvider = TransactionDetails.OperationSectionsProvider(
            transactionsProvider: transactionsProvider,
            emailFetcher: emailFetcher,
            identifier: transactionId,
            accountId: self.userDataProvider.walletData.accountId
        )
        let vc = self.setupTransactionDetailsScreen(
            navigationController: navigationController,
            sectionsProvider: sectionsProvider,
            title: Localized(.transaction_details),
            completion: completion
        )
        navigationController.pushViewController(vc, animated: true)
    }
    
    func runSendPaymentFlow(
        navigationController: NavigationControllerProtocol,
        balanceId: String?,
        completion: @escaping (() -> Void)
        ) {
        
        let flow = SendPaymentFlowController(
            navigationController: navigationController,
            appController: self.appController,
            flowControllerStack: self.flowControllerStack,
            reposController: self.reposController,
            managersController: self.managersController,
            userDataProvider: self.userDataProvider,
            keychainDataProvider: self.keychainDataProvider,
            rootNavigation: self.rootNavigation,
            selectedBalanceId: balanceId
        )
        self.currentFlowController = flow
        flow.run(
            showRootScreen: { (vc) in
                navigationController.pushViewController(vc, animated: true)
        },
            onShowMovements: { [weak self] in
                self?.currentFlowController = nil
                completion()
        })
    }
    
    func runWithdrawFlow(
        navigationController: NavigationControllerProtocol,
        balanceId: String?,
        completion: @escaping (() -> Void)
        ) {
        
        let flow = WithdrawFlowController(
            appController: self.appController,
            flowControllerStack: self.flowControllerStack,
            reposController: self.reposController,
            managersController: self.managersController,
            userDataProvider: self.userDataProvider,
            keychainDataProvider: self.keychainDataProvider,
            rootNavigation: self.rootNavigation,
            navigationController: navigationController,
            selectedBalanceId: balanceId
        )
        self.currentFlowController = flow
        flow.run(
            showRootScreen: { (vc) in
                navigationController.pushViewController(vc, animated: true)
        },
            onShowMovements: { [weak self] in
                self?.currentFlowController = nil
                completion()
        })
    }
    
    func showDepositScreen(
        navigationController: NavigationControllerProtocol,
        assetId: String?
        ) {
        
        let viewController = DepositScene.ViewController()
        
        let sceneModel = DepositScene.Model.SceneModel(
            selectedAssetId: assetId ?? "",
            assets: [],
            qrCodeSize: .zero
        )
        
        let qrCodeGenerator = QRCodeGenerator()
        let dateFormatter = DepositScene.DateFormatter()
        let assetsFetcher = DepositScene.AssetsFetcher(
            assetsRepo: self.reposController.assetsRepo,
            balancesRepo: self.reposController.balancesRepo,
            accountRepo: self.reposController.accountRepo,
            externalSystemBalancesManager: self.managersController.externalSystemBalancesManager
        )
        let balanceBinder = BalanceBinder(
            balancesRepo: self.reposController.balancesRepo,
            accountRepo: self.reposController.accountRepo,
            externalSystemBalancesManager: self.managersController.externalSystemBalancesManager
        )
        let addressManager = DepositScene.AddressManager(
            balanceBinder: balanceBinder
        )
        
        let errorFormatter = DepositScene.ErrorFormatter()
        
        let routing = DepositScene.Routing(
            onShare: { [weak self] (items) in
                self?.shareItems(
                    navigationController: navigationController,
                    items
                )
            },
            onError: { (message) in
                navigationController.showErrorMessage(message, completion: nil)
        })
        
        DepositScene.Configurator.configure(
            viewController: viewController,
            sceneModel: sceneModel,
            qrCodeGenerator: qrCodeGenerator,
            dateFormatter: dateFormatter,
            assetsFetcher: assetsFetcher,
            addressManager: addressManager,
            errorFormatter: errorFormatter,
            routing: routing
        )
        
        viewController.navigationItem.title = Localized(.deposit)
        navigationController.pushViewController(viewController, animated: true)
    }
    
    func showReceiveScene(navigationController: NavigationControllerProtocol) {
        let vc = ReceiveAddress.ViewController()
        
        let viewConfig = ReceiveAddress.Model.ViewConfig(
            copiedLocalizationKey: Localized(.copied),
            tableViewTopInset: 24
        )
        
        let addressManager = ReceiveAddress.ReceiveAddressManager(
            accountId: self.userDataProvider.walletData.accountId
        )
        
        let sceneModel = ReceiveAddress.Model.SceneModel()
        
        let qrCodeGenerator = QRCodeGenerator()
        let shareUtil = ReceiveAddress.ReceiveAddressShareUtil(
            qrCodeGenerator: qrCodeGenerator
        )
        
        let invoiceFormatter = ReceiveAddress.InvoiceFormatter()
        
        let routing = ReceiveAddress.Routing(
            onCopy: { (stringToCopy) in
                UIPasteboard.general.string = stringToCopy
        },
            onShare: { [weak self] (itemsToShare) in
                self?.shareItems(
                    navigationController: navigationController,
                    itemsToShare
                )
        })
        
        ReceiveAddress.Configurator.configure(
            viewController: vc,
            viewConfig: viewConfig,
            sceneModel: sceneModel,
            addressManager: addressManager,
            shareUtil: shareUtil,
            qrCodeGenerator: qrCodeGenerator,
            invoiceFormatter: invoiceFormatter,
            routing: routing
        )
        
        vc.navigationItem.title = Localized(.receive)
        navigationController.pushViewController(vc, animated: true)
    }
    
    func setupTransactionDetailsScreen(
        navigationController: NavigationControllerProtocol,
        sectionsProvider: TransactionDetails.SectionsProviderProtocol,
        title: String,
        completion: (() -> Void)? = nil
        ) -> TransactionDetails.ViewController {
        
        let routing = TransactionDetails.Routing(
            successAction: {
                completion?()
                navigationController.popViewController(true)
        },
            showProgress: {
                navigationController.showProgress()
        },
            hideProgress: {
                navigationController.hideProgress()
        },
            showError: { (error) in
                navigationController.showErrorMessage(error, completion: nil)
        },
            showMessage: { [weak self] (message) in
                let present = navigationController.getPresentViewControllerClosure()
                self?.showSuccessMessage(
                    title: message,
                    message: nil,
                    completion: nil,
                    presentViewController: present
                )
            },
            showDialog: { [weak self] (title, message, options, onSelected) in
                let present = navigationController.getPresentViewControllerClosure()
                self?.showDialog(
                    title: title,
                    message: message,
                    style: .alert,
                    options: options,
                    onSelected: onSelected,
                    onCanceled: nil,
                    presentViewController: present
                )}
        )
        
        let vc = SharedSceneBuilder.createTransactionDetailsScene(
            sectionsProvider: sectionsProvider,
            routing: routing
        )
        
        vc.navigationItem.title = title
        
        return vc
    }
    
    // MARK: - Private
    
    private func shareItems(
        navigationController: NavigationControllerProtocol,
        _ items: [Any]
        ) {
        
        let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
        navigationController.present(activity, animated: true, completion: nil)
    }
}
