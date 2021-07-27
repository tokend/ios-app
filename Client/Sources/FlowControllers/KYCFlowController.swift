import UIKit

class KYCFlowController: BaseSignedInFlowController {

    typealias OnKYCFinished = () -> Void
    typealias OnKYCFailed = () -> Void
    typealias OnBack = () -> Void

    private let navigationController: NavigationControllerProtocol

    private let onKYCFinished: OnKYCFinished
    private let onKYCFailed: OnKYCFailed
    private let onBack: OnBack

    private let kycChecker: AccountKYCCheckerProtocol
    private let roleProvider: AccountKYCRoleProviderProtocol
    private let kycSender: AccountKYCFormSenderProtocol

    init(
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        reposController: ReposController,
        managersController: ManagersController,
        userDataProvider: UserDataProviderProtocol,
        keychainDataProvider: KeychainDataProviderProtocol,
        rootNavigation: RootNavigationProtocol,
        onKYCFinished: @escaping OnKYCFinished,
        onKYCFailed: @escaping OnKYCFailed,
        onBack: @escaping OnBack,
        navigationController: NavigationControllerProtocol
        ) {

        self.onKYCFinished = onKYCFinished
        self.onKYCFailed = onKYCFailed
        self.onBack = onBack

        self.kycChecker = ActiveKYCChecker(
            latestChangeRoleRequestProvider: managersController.latestChangeRoleRequestProvider
        )
        self.kycSender = managersController.accountKYCFormSender
        self.roleProvider = RegistrationKYCRoleProvider(
            keyValuesApi: flowControllerStack.apiV3.keyValuesApi,
            accountType: managersController.accountTypeManager.getType(),
            originalAccountId: userDataProvider.walletData.accountId
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

private extension KYCFlowController {

    func checkKYC() {
        
        navigationController.showProgress()
        kycChecker.checkKYC({ [weak self] (result) in

            self?.navigationController.hideProgress()
            
            switch result {

            case .error(let error):
                self?.navigationController.showErrorMessage(
                    error.localizedDescription,
                    completion: { [weak self] in
                        self?.onKYCFailed()
                    }
                )

            case .success(let state):
                
                switch state {
                
                case .approved:
                    self?.onKYCFinished()
                    
                case .canceled,
                     .pending,
                     .permanentlyRejected,
                     .rejected,
                     .unknown:
                    break
                // TODO: - Implement
                }

            case .noKyc:
                self?.onKYCFinished()
            }
        })
    }

    // MARK: - KYC Sender

    func sendKYC(
        firstName: String,
        lastName: String,
        kycAvatar: AccountKYCForm.KYCDocument,
        kycIdDocument: AccountKYCForm.KYCDocument
    ) {

        let form: AccountKYCForm = ActiveKYCRepo.KYCForm(documents: .init(kycAvatar: nil))

        navigationController.showProgress()
        roleProvider.fetchRoleId({ [weak self] (result) in

            switch result {

            case .failure:
                self?.navigationController.hideProgress()
                self?.navigationController.showErrorMessage(
                    Localized(.error_unknown),
                    completion: nil
                )

            case .success(let roleId):
                self?.kycSender.sendKYCForm(
                    form,
                    roleId: roleId,
                    completion: { [weak self] (result) in

                        self?.navigationController.hideProgress()
                        
                        switch result {

                        case .failure:
                            self?.navigationController.showErrorMessage(
                                Localized(.error_unknown),
                                completion: nil
                            )

                        case .success:
                            self?.reposController.activeKycRepo.requestActiveKYC(
                                completion: { [weak self] (_) in
                                    self?.onKYCFinished()
                            })
                        }
                })
            }
        })
    }
}

// MARK: - Public methods

extension KYCFlowController {

    func run() {
        checkKYC()
    }
}
