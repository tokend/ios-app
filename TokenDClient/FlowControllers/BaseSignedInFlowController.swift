import UIKit

class BaseSignedInFlowController: BaseFlowController {
    
    let reposController: ReposController
    let managersController: ManagersController
    let userDataProvider: UserDataProviderProtocol
    let keychainDataProvider: KeychainDataProviderProtocol
    var accountType: AccountType {
        managersController.accountTypeManager.accountType
    }
    
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
    
    // MARK: - Private
    
    private func shareItems(
        navigationController: NavigationControllerProtocol,
        _ items: [Any]
        ) {
        
        let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
        navigationController.present(activity, animated: true, completion: nil)
    }
}
