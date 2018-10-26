import Foundation

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
}
