import UIKit

class SettingsFlowController: BaseSignedInFlowController {
    
    // MARK: - Private properties
    
    private let navigationController: NavigationControllerProtocol = NavigationController()
    
    // MARK: - Public
    
    public func run(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        self.showSettingsScreen(showRootScreen: showRootScreen)
    }
    
    // MARK: - Private
    
    private func showSettingsScreen(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        let vc = Settings.ViewController()
        
        let sectionsProvider = Settings.SettingsSectionsProvider(
            settingsManger: self.flowControllerStack.settingsManager,
            userDataProvider: self.userDataProvider,
            apiConfigurationModel: self.flowControllerStack.apiConfigurationModel,
            tfaApi: self.flowControllerStack.api.tfaApi,
            onPresentAlert: { [weak self] alert in
                self?.navigationController.present(alert, animated: true, completion: nil)
        })
        
        let rounting = Settings.Routing(
            showProgress: { [weak self] in
                self?.navigationController.showProgress()
            },
            hideProgress: { [weak self] in
                self?.navigationController.hideProgress()
            },
            showErrorMessage: { [weak self] errorMessage in
                self?.navigationController.showErrorMessage(errorMessage, completion: nil)
            },
            onCellSelected: { [weak self] (cellIdentifier) in
                self?.switchToSetting(cellIdentifier)
        })
        
        Settings.Configurator.configure(
            viewController: vc,
            sectionsProvider: sectionsProvider,
            routing: rounting
        )
        
        self.navigationController.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: Theme.Fonts.navigationBarBoldFont,
            NSAttributedString.Key.foregroundColor: Theme.Colors.textOnMainColor
        ]
        
        vc.navigationItem.title = "Settings"
        
        self.navigationController.setViewControllers([vc], animated: false)
        
        if let showRoot = showRootScreen {
            showRoot(self.navigationController.getViewController())
        } else {
            self.rootNavigation.setRootContent(self.navigationController, transition: .fade, animated: false)
        }
    }
    
    private func switchToSetting(_ identifier: Settings.CellIdentifier) {
        switch identifier {
            
        case Settings.SettingsSectionsProvider.accountIdCellIdentifier:
            self.showAccountIdScreen()
            
        case Settings.SettingsSectionsProvider.verificationCellIdentifier:
            self.showVerificationScreen()
            
        case Settings.SettingsSectionsProvider.changePasswordCellIdentifier:
            self.showChangePasswordScreen()
            
        default:
            break
        }
    }
    
    // MARK: - Settings
    
    private func showAccountIdScreen() {
        let vc = ReceiveAddress.ViewController()
        
        let viewConfig = ReceiveAddress.Model.ViewConfig(
            copiedLocalizationKey: "Copied",
            tableViewTopInset: 24
        )
        
        let sceneModel = ReceiveAddress.Model.SceneModel()
        
        let addressManager = ReceiveAddress.ReceiveAddressManager(accountId: self.userDataProvider.walletData.accountId)
        
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
        
        vc.navigationItem.title = "Account ID"
        
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func shareItems(_ items: [Any]) {
        let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
        self.navigationController.present(activity, animated: true, completion: nil)
    }
    
    private func showVerificationScreen() {
        guard let urlString = self.flowControllerStack.apiConfigurationModel.webClient,
            let url = URL(string: urlString) else {
                return
        }
        
        UIApplication.shared.open(
            url,
            options: [:],
            completionHandler: nil
        )
    }
    
    private func showChangePasswordScreen() {
        let vc = self.setupChangePasswordScreen(onSuccess: { [weak self] in
            self?.navigationController.popViewController(true)
        })
        
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func setupChangePasswordScreen(onSuccess: @escaping () -> Void) -> UpdatePassword.ViewController {
        let vc = UpdatePassword.ViewController()
        
        let submitPasswordHandler = UpdatePassword.ChangePasswordWorker(
            keyserverApi: self.flowControllerStack.keyServerApi,
            keychainManager: self.managersController.keychainManager,
            userDataManager: self.managersController.userDataManager,
            userDataProvider: self.userDataProvider,
            networkInfoFetcher: self.flowControllerStack.networkInfoFetcher
        )
        
        let fields = submitPasswordHandler.getExpectedFields()
        let sceneModel = UpdatePassword.Model.SceneModel(fields: fields)
        
        let routing = UpdatePassword.Routing(
            onShowProgress: { [weak self] in
                self?.navigationController.showProgress()
            },
            onHideProgress: { [weak self] in
                self?.navigationController.hideProgress()
            },
            onShowErrorMessage: { [weak self] (errorMessage) in
                self?.navigationController.showErrorMessage(errorMessage, completion: nil)
            },
            onSubmitSucceeded: {
                onSuccess()
        })
        
        UpdatePassword.Configurator.configure(
            viewController: vc,
            sceneModel: sceneModel,
            submitPasswordHandler: submitPasswordHandler,
            routing: routing
        )
        
        vc.navigationItem.title = "Change Password"
        
        return vc
    }
}
