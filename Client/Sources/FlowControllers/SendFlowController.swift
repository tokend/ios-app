import Foundation
import TokenDSDK

class SendFlowController: BaseSignedInFlowController {
    
    // MARK: - Private properties
    
    private lazy var rootViewController: SendAssetScene.ViewController = initSendAsset()
    
    private let navigationController: NavigationControllerProtocol
    private let recipientAddressProcessor: RecipientAddressProcessorProtocol
    fileprivate let balanceId: String

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
        assetId: String
    ) {

        self.navigationController = navigationController
        self.balanceId = assetId
        
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
        let vc: SendAmountScene.ViewController = initSendAmount(
            recipientAccountId: recipientAccountId,
            recipientEmail: recipientEmail
        )
        
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    func initSendAmount(
        recipientAccountId: String,
        recipientEmail: String?
    ) -> SendAmountScene.ViewController {
    
        let vc: SendAmountScene.ViewController = .init()
        
        let routing: SendAmountScene.Routing = .init(
            onSelectBalance: { [weak self] (completion) in
                
            },
            onContinue: { [weak self] in
                
            }
        )
        
        guard let selectedBalance = reposController.balancesRepo.balancesDetails.first(where: {
            
            switch $0 {
            
            case .creating:
                return false
                
            case .created(let balance):
                return balance.id == self.balanceId
            }
        })
        else {
            fatalError()
        }
        
        let selectedBalanceProvider: SendAmountScene.SelectedBalanceProviderProtocol = SendAmountScene.SelectedBalanceProvider(
            selectedBalance: try! selectedBalance.mapToBalance()
        )
        
        let feesProcessor: SendAmountScene.FeesProcessorProtocol = SendAmountScene.FeesProcessor(
            originalAccountId: userDataProvider.walletData.accountId,
            recipientAccountId: recipientAccountId,
            feesApi: flowControllerStack.apiV3.feesApi
        )
        
        SendAmountScene.Configurator.configure(
            viewController: vc,
            routing: routing,
            recipientAddress: recipientEmail ?? recipientAccountId,
            selectedBalanceProvider: selectedBalanceProvider,
            feesProcessor: feesProcessor
        )
        
        return vc
    }
}

private enum SelectedBalanceProviderMapperError: Swift.Error {
    case noBalance
}

private extension BalancesRepo.BalanceState {
    func mapToBalance(
    ) throws -> SendAmountScene.Model.Balance {
        
        switch self {
        
        case .creating:
            throw SelectedBalanceProviderMapperError.noBalance
            
        case .created(let balance):
            
            return .init(
                id: balance.id,
                assetCode: balance.asset.id,
                amount: balance.balance
            )
        }
    }
}
