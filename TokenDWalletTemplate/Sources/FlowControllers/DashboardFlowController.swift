import UIKit
import RxSwift

class DashboardFlowController: BaseSignedInFlowController {
    
    // MARK: - Private
    
    private let navigationController: NavigationControllerProtocol =
        NavigationController()
    private weak var dashboardScene: TabBarContainer.ViewController?
    private var operationCompletionScene: UIViewController {
        return self.dashboardScene ?? UIViewController()
    }
    private let disposeBag: DisposeBag = DisposeBag()
    
    // MARK: - Public
    
    public func run(
        showRootScreen: ((_ vc: UIViewController) -> Void)?,
        selectedTabIdentifier: TabsContainer.Model.TabIdentifier?
        ) {
        
        self.showDashboardScreen(
            showRootScreen: showRootScreen,
            selectedTabIdentifier: selectedTabIdentifier
        )
    }
    
    // MARK: - Private
    
    private func showMovements() {
        _ = self.navigationController.popToViewController(
            self.operationCompletionScene,
            animated: true
        )
        self.dashboardScene?.setSelectedContentWithIdentifier(
            idetifier: Localized(.movements)
        )
    }
    
    private func showDashboardScreen(
        showRootScreen: ((_ vc: UIViewController) -> Void)?,
        selectedTabIdentifier: TabsContainer.Model.TabIdentifier?
        ) {
        
        let container = TabBarContainer.ViewController()
        let transactionsProvider = TransactionsListScene.MovementsProvider(
            movementsRepo: self.reposController.movementsRepo
        )
        let transactionsFetcher = TransactionsListScene.PaymentsFetcher(
            transactionsProvider: transactionsProvider
        )
        let imagesUtility = ImagesUtility(
            storageUrl: self.flowControllerStack.apiConfigurationModel.storageEndpoint
        )
        let balancesFetcher = BalancesList.BalancesFetcher(
            balancesRepo: self.reposController.balancesRepo,
            assetsRepo: self.reposController.assetsRepo,
            imageUtility: imagesUtility
        )
        let actionProvider = TransactionsListScene.ActionProvider(
            assetsRepo: self.reposController.assetsRepo,
            balancesRepo: self.reposController.balancesRepo
        )
        let amountFormatter = TransactionsListScene.AmountFormatter()
        let dateFormatter = TransactionsListScene.DateFormatter()
        let colorsProvider = BalancesList.PieChartColorsProvider()
        
        let contentProvider = TabBarContainer.DashboardProvider(
            transactionsFetcher: transactionsFetcher,
            balancesFetcher: balancesFetcher,
            actionProvider: actionProvider,
            amountFormatter: amountFormatter,
            dateFormatter: dateFormatter,
            colorsProvider: colorsProvider,
            onDidSelectItemWithIdentifier: { [weak self] (transactionId, balanceId) in
                guard let navigationContrpller = self?.navigationController else {
                    return
                }
                self?.showTransactionDetailsScreen(
                    transactionsProvider: transactionsProvider,
                    navigationController: navigationContrpller,
                    transactionId: transactionId,
                    balanceId: balanceId
                )
            },
            showPaymentsFor: { [weak self] (balanceId) in
                self?.showPaymentsFor(selectedBalanceId: balanceId)
            }, showSendScene: { [weak self] in
                self?.showSendScene()
            }, showReceiveScene: { [weak self] in
                self?.showReceiveScene()
            }, showProgress: { [weak self] in
                self?.navigationController.showProgress()
            }, hideProgress: { [weak self] in
                self?.navigationController.hideProgress()
            }, showShadow: { [weak self] in
                self?.navigationController.showShadow()
            }, hideShadow: { [weak self] in
                self?.navigationController.hideShadow()
            },
               selectedTabIdentifier: selectedTabIdentifier
        )
        let routing = TabBarContainer.Routing()
        
        self.dashboardScene = container
        TabBarContainer.Configurator.configure(
            viewController: container,
            contentProvider: contentProvider,
            routing: routing
        )
        
        let exploreAssetsItem = UIBarButtonItem(
            image: Assets.plusIcon.image,
            style: .plain,
            target: nil,
            action: nil
        )
        exploreAssetsItem
            .rx
            .tap
            .asDriver()
            .drive(onNext: { [weak self] (_) in
                self?.runExploreTokensFlow()
            })
            .disposed(by: self.disposeBag)
        
        container.navigationItem.rightBarButtonItem = exploreAssetsItem
        self.navigationController.setViewControllers([container], animated: false)
        
        if let showRoot = showRootScreen {
            showRoot(self.navigationController.getViewController())
        } else {
            self.rootNavigation.setRootContent(self.navigationController, transition: .fade, animated: false)
        }
    }
    
    private func showSendScene() {
        self.runSendPaymentFlow(
            navigationController: self.navigationController,
            balanceId: nil,
            completion: { [weak self] in
                self?.showMovements()
        })
    }
    
    private func showReceiveScene() {
        let vc = ReceiveAddress.ViewController()
        
        let addressManager = ReceiveAddress.ReceiveAddressManager(
            accountId: self.userDataProvider.walletData.accountId
        )
        
        let viewConfig = ReceiveAddress.Model.ViewConfig(
            copiedLocalizationKey: Localized(.copied),
            tableViewTopInset: 24
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
                self?.shareItems(itemsToShare)
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
        
        vc.navigationItem.title = Localized(.account_id)
        vc.tabBarItem.title = Localized(.receive)
        vc.tabBarItem.image = Assets.receive.image
        
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func showPaymentsFor(selectedBalanceId: String) {
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
                    navigationController: navigationController,
                    transactionId: identifier,
                    balanceId: balanceId
                )
            },
            showSendPayment: { [weak self] (balanceId) in
                self?.runSendPaymentFlow(
                    navigationController: navigationController,
                    balanceId: balanceId,
                    completion: { [weak self] in
                        self?.showMovements()
                })
            },
            showWithdraw: { [weak self] (balanceId) in
                self?.runWithdrawFlow(
                    navigationController: navigationController,
                    balanceId: balanceId,
                    completion: { [weak self] in
                        self?.showMovements()
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
            },
            showShadow: { [weak self] in
                self?.navigationController.showShadow()
            },
            hideShadow: { [weak self] in
                self?.navigationController.hideShadow()
        })
        
        let imageUtility = ImagesUtility(
            storageUrl: self.flowControllerStack.apiConfigurationModel.storageEndpoint
        )
        let balanceFetcher = BalanceHeader.BalancesFetcher(
            balancesRepo: self.reposController.balancesRepo,
            assetsRepo: self.reposController.assetsRepo,
            imageUtility: imageUtility,
            balanceId: selectedBalanceId
        )
        let headerRateProvider: BalanceHeader.RateProviderProtocol = RateProvider(
            assetPairsRepo: self.reposController.assetPairsRepo
        )
        let container = SharedSceneBuilder.createBalanceDetailsScene(
            transactionsFetcher: transactionsFetcher,
            actionProvider: actionProvider,
            transactionsRouting: transactionsRouting,
            viewConfig: viewConfig,
            headerRateProvider: headerRateProvider,
            balanceFetcher: balanceFetcher,
            balanceId: selectedBalanceId
        )
        self.navigationController.pushViewController(container, animated: true)
    }
    
    private func showPendingOffers() {
        let decimalFormatter = DecimalFormatter()
        let transactionsFetcher = TransactionsListScene.PendingOffersFetcher(
            pendingOffersRepo: self.reposController.pendingOffersRepo,
            balancesRepo: self.reposController.balancesRepo,
            decimalFormatter: decimalFormatter,
            originalAccountId: self.userDataProvider.walletData.accountId
        )
        
        let actionProvider = TransactionsListScene.ActionProvider(
            assetsRepo: self.reposController.assetsRepo,
            balancesRepo: self.reposController.balancesRepo
        )
        
        let viewConfig = TransactionsListScene.Model.ViewConfig(actionButtonIsHidden: true)
        
        let transactionsListRouting = TransactionsListScene.Routing(
            onDidSelectItemWithIdentifier: { [weak self] (identifier, _) in
                self?.showPendingOfferDetailsScreen(offerId: identifier)
            },
            showSendPayment: { _ in },
            showWithdraw: { _ in },
            showDeposit: { _ in },
            showReceive: { },
            showShadow: { [weak self] in
                self?.navigationController.showShadow()
            },
            hideShadow: { [weak self] in
                self?.navigationController.hideShadow()
            }
        )
        
        let viewController = SharedSceneBuilder.createTransactionsListScene(
            transactionsFetcher: transactionsFetcher,
            actionProvider: actionProvider,
            emptyTitle: Localized(.no_pending_orders),
            viewConfig: viewConfig,
            routing: transactionsListRouting
        )
        
        viewController.navigationItem.title = Localized(.pending_orders)
        
        self.navigationController.pushViewController(viewController, animated: true)
    }
    
    private func showPendingOfferDetailsScreen(
        offerId: UInt64
        ) {
        
        let sectionsProvider = TransactionDetails.PendingOfferSectionsProvider(
            pendingOffersRepo: self.reposController.pendingOffersRepo,
            transactionSender: self.managersController.transactionSender,
            amountConverter: AmountConverter(),
            networkInfoFetcher: self.flowControllerStack.networkInfoFetcher,
            userDataProvider: self.userDataProvider,
            identifier: offerId
        )
        let vc = self.setupTransactionDetailsScreen(
            navigationController: self.navigationController,
            sectionsProvider: sectionsProvider,
            title: Localized(.pending_order_details)
        )
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func runExploreTokensFlow() {
        let exploreTokensFlowController = ExploreTokensFlowController(
            navigationController: self.navigationController,
            appController: self.appController,
            flowControllerStack: self.flowControllerStack,
            reposController: self.reposController,
            managersController: self.managersController,
            userDataProvider: self.userDataProvider,
            keychainDataProvider: self.keychainDataProvider,
            rootNavigation: self.rootNavigation
        )
        self.currentFlowController = exploreTokensFlowController
        exploreTokensFlowController.run(showRootScreen: { [weak self] (vc) in
            self?.navigationController.pushViewController(vc, animated: true)
        })
    }
    
    private func shareItems(_ items: [Any]) {
        let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
        self.navigationController.present(activity, animated: true, completion: nil)
    }
}
