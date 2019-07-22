import UIKit

class WalletDetailsFlowController: BaseSignedInFlowController {
    
    // MARK: - Private properties
    
    private let navigationController: NavigationControllerProtocol = NavigationController()
    private weak var walletScene: UIViewController?
    private var operationCompletionScene: UIViewController {
        return self.walletScene ?? UIViewController()
    }
    
    // MARK: - Public
    
    public func run(
        showRootScreen: ((_ vc: UIViewController) -> Void)?,
        selectedBalanceId: BalanceHeaderWithPicker.Identifier
        ) {
        
        self.showWalletScreen(
            showRootScreen: showRootScreen,
            selectedBalanceId: selectedBalanceId
        )
    }
    
    // MARK: - Private
    
    private func goBackToWalletScene() {
        _ = self.navigationController.popToViewController(
            self.operationCompletionScene,
            animated: true
        )
    }
    
    private func showWalletScreen(
        showRootScreen: ((_ vc: UIViewController) -> Void)?,
        selectedBalanceId: BalanceHeaderWithPicker.Identifier
        ) {
        
        let transactionsProvider = TransactionsListScene.HistoryProvider(
            reposController: self.reposController,
            originalAccountId: self.userDataProvider.walletData.accountId
        )
        let transactionsFetcher = TransactionsListScene.PaymentsFetcher(
            transactionsProvider: transactionsProvider
        )
        let actionProvider = TransactionsListScene.ActionProvider(
            assetsRepo: self.reposController.assetsRepo,
            balancesRepo: self.reposController.balancesRepo
        )
        let viewConfig = TransactionsListScene.Model.ViewConfig(actionButtonIsHidden: false)
        
        let navigationController = self.navigationController
        let transactionsRouting = TransactionsListScene.Routing (
            onDidSelectItemWithIdentifier: { [weak self] (identifier, balanceId) in
                self?.showTransactionDetailsScreen(
                    transactionsProvider: transactionsProvider,
                    transactionId: identifier,
                    balanceId: balanceId
                )
            },
            showSendPayment: { [weak self] (balanceId) in
                self?.runSendPaymentFlow(
                    navigationController: navigationController,
                    balanceId: balanceId,
                    completion: { [weak self] in
                        self?.goBackToWalletScene()
                })
            },
            showWithdraw: { [weak self] (balanceId) in
                self?.runWithdrawFlow(
                    navigationController: navigationController,
                    balanceId: balanceId,
                    completion: { [weak self] in
                        self?.goBackToWalletScene()
                })
            },
            showDeposit: { [weak self] (asset) in
                self?.showDepositScreen(
                    navigationController: navigationController,
                    assetId: asset
                )
            },
            showReceive: { [weak self] in
                self?.showReceiveScene(navigationController: navigationController)
            }, showShadow: { [weak self] in
                self?.navigationController.showShadow()
            }, hideShadow: { [weak self] in
                self?.navigationController.hideShadow()
        })
        
        let imageUtility = ImagesUtility(
            storageUrl: self.flowControllerStack.apiConfigurationModel.storageEndpoint
        )
        let balancesFetcher = BalanceHeader.BalancesFetcher(
            balancesRepo: self.reposController.balancesRepo,
            assetsRepo: self.reposController.assetsRepo,
            imageUtility: imageUtility,
            balanceId: selectedBalanceId
        )
        
        let container = SharedSceneBuilder.createBalanceDetailsScene(
            transactionsFetcher: transactionsFetcher,
            actionProvider: actionProvider,
            transactionsRouting: transactionsRouting,
            viewConfig: viewConfig,
            balanceFetcher: balancesFetcher,
            balanceId: selectedBalanceId
        )
        
        self.walletScene = container
        self.navigationController.setViewControllers([container], animated: false)
        
        if let showRoot = showRootScreen {
            showRoot(self.navigationController.getViewController())
        } else {
            self.rootNavigation.setRootContent(self.navigationController, transition: .fade, animated: false)
        }
    }
    
    private func showTransactionDetailsScreen(
        transactionsProvider: TransactionDetails.TransactionsProviderProtocol,
        transactionId: UInt64,
        balanceId: String
        ) {
        let vc = self.setupTransactionDetailsScreen(
            transactionsProvider: transactionsProvider,
            transactionId: transactionId,
            balanceId: balanceId
        )
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func setupTransactionDetailsScreen(
        transactionsProvider: TransactionDetails.TransactionsProviderProtocol,
        transactionId: UInt64,
        balanceId: String
        ) -> TransactionDetails.ViewController {
        
        let routing = TransactionDetails.Routing(
            successAction: { [weak self] in
                self?.navigationController.popViewController(true)
            },
            showProgress: { [weak self] in
                self?.navigationController.showProgress()
            },
            hideProgress: { [weak self] in
                self?.navigationController.hideProgress()
            },
            showError: { [weak self] (error) in
                self?.navigationController.showErrorMessage(error, completion: nil)
            },
            showMessage: { [weak self] (message) in
                guard let present = self?.navigationController.getPresentViewControllerClosure() else {
                    return
                }
                self?.showSuccessMessage(
                    title: message,
                    message: nil,
                    completion: nil,
                    presentViewController: present
                )
            }, showDialog: { [weak self] (title, message, options, onSelected) in
                guard let present = self?.navigationController.getPresentViewControllerClosure() else {
                    return
                }
                self?.showDialog(
                    title: title,
                    message: message,
                    style: .alert,
                    options: options,
                    onSelected: onSelected,
                    onCanceled: nil,
                    presentViewController: present
                )
        })
        
        let emailFetcher = TransactionDetails.EmailFetcher(
            generalApi: self.flowControllerStack.api.generalApi
        )
        let sectionsProvider = TransactionDetails.OperationSectionsProvider(
            transactionsProvider: transactionsProvider,
            emailFetcher: emailFetcher,
            identifier: transactionId,
            accountId: self.userDataProvider.walletData.accountId
        )
        let vc = SharedSceneBuilder.createTransactionDetailsScene(
            sectionsProvider: sectionsProvider,
            routing: routing
        )
        
        vc.navigationItem.title = Localized(.transaction_details)
        
        return vc
    }
}
