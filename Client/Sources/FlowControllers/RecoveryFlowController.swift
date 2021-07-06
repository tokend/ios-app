import UIKit

class RecoveryFlowController: BaseSignedInFlowController {

    typealias OnRecoveryFinished = () -> Void
    typealias OnRecoveryFailed = () -> Void

    private let navigationController: NavigationControllerProtocol

    private let onRecoveryFinished: OnRecoveryFinished
    private let onRecoveryFailed: OnRecoveryFailed

    private let recoveryStatusChecker: RecoveryStatusCheckerProtocol

    init(
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        reposController: ReposController,
        managersController: ManagersController,
        userDataProvider: UserDataProviderProtocol,
        keychainDataProvider: KeychainDataProviderProtocol,
        rootNavigation: RootNavigationProtocol,
        onRecoveryFinished: @escaping OnRecoveryFinished,
        onRecoveryFailed: @escaping OnRecoveryFailed,
        navigationController: NavigationControllerProtocol
    ) {

        self.onRecoveryFinished = onRecoveryFinished
        self.onRecoveryFailed = onRecoveryFailed

        recoveryStatusChecker = RecoveryStatusChecker(
            accountsApi: flowControllerStack.apiV3.accountsApi,
            keyServerApi: flowControllerStack.keyServerApi,
            transactionCreator: managersController.transactionCreator,
            transactionSender: managersController.transactionSender,
            userDataProvider: userDataProvider,
            keychainDataProvider: keychainDataProvider
        )

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
}

// MARK: - Private methods

private extension RecoveryFlowController {

    func checkRecovery() {
        navigationController.showProgress()
        recoveryStatusChecker.checkRecoveryStatus({ [weak self] (result) in

            self?.navigationController.hideProgress()
            
            switch result {

            case .failure:
                self?.onRecoveryFailed()

            case .success:
                self?.onRecoveryFinished()
            }
        })
    }
}

// MARK: - Public methods

extension RecoveryFlowController {

    func run() {
        checkRecovery()
    }
}
