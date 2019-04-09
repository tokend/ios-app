import UIKit
import LocalAuthentication
import RxSwift
import RxCocoa
import TokenDSDK

enum SettingsSectionsProviderHandleBoolCellResult {
    case succeded
    case failed(Error)
}

enum SettingsSectionsProviderHandleActionCellResult {
    case succeeded
    case failed(Error)
}

protocol SettingsSectionsProviderProtocol {
    func observeSections() -> Observable<[Settings.Model.SectionModel]>
    
    func handleBoolCell(
        cellIdentifier: Settings.CellIdentifier,
        state: Bool,
        startLoading: @escaping () -> Void,
        stopLoading: @escaping () -> Void,
        completion: @escaping (_ result: SettingsSectionsProviderHandleBoolCellResult) -> Void
    )
    
    func handleActionCell(
        cellIdentifier: Settings.CellIdentifier,
        startLoading: @escaping () -> Void,
        stopLoading: @escaping () -> Void,
        completion: @escaping (_ result: SettingsSectionsProviderHandleActionCellResult) -> Void
    )
    
    func isTermsCell(cellIdentifier: Settings.CellIdentifier) -> Bool
}

extension Settings {
    
    typealias SectionsProvider = SettingsSectionsProviderProtocol
    
    // swiftlint:disable type_body_length
    class SettingsSectionsProvider: SettingsSectionsProviderProtocol {
        
        // MARK: - Public properties
        
        let settingsManger: SettingsManagerProtocol
        let userDataProvider: UserDataProviderProtocol
        let tfaApi: TFAApi
        let apiConfigurationModel: APIConfigurationModel
        let onPresentAlert: (_ alert: UIAlertController) -> Void
        
        // MARK: - Private properties
        
        private let sections: BehaviorRelay<[Model.SectionModel]> = BehaviorRelay(value: [])
        
        private var tfaEnabledState: TFAEnabledState = .undetermined
        
        // MARK: -
        
        init(
            settingsManger: SettingsManagerProtocol,
            userDataProvider: UserDataProviderProtocol,
            apiConfigurationModel: APIConfigurationModel,
            tfaApi: TFAApi,
            onPresentAlert: @escaping (_ alert: UIAlertController) -> Void
            ) {
            
            self.settingsManger = settingsManger
            self.userDataProvider = userDataProvider
            self.tfaApi = tfaApi
            self.apiConfigurationModel = apiConfigurationModel
            self.onPresentAlert = onPresentAlert
        }
        
        // MARK: - SettingsSectionsProviderProtocol
        
        func observeSections() -> Observable<[Model.SectionModel]> {
            self.updateSections()
            
            return self.sections.asObservable()
        }
        
        func handleBoolCell(
            cellIdentifier: CellIdentifier,
            state: Bool,
            startLoading: @escaping () -> Void,
            stopLoading: @escaping () -> Void,
            completion: @escaping (_ result: SettingsSectionsProviderHandleBoolCellResult) -> Void
            ) {
            
            switch cellIdentifier {
                
            case .biometrics:
                self.handleBiometricsEnabled(state, completion: completion)
                return
                
            case .tfa:
                self.handleTFAEnabled(
                    state,
                    startLoading: startLoading,
                    stopLoading: stopLoading,
                    completion: completion
                )
                return
                
            default:
                break
            }
        }
        
        func handleActionCell(
            cellIdentifier: CellIdentifier,
            startLoading: @escaping () -> Void,
            stopLoading: @escaping () -> Void,
            completion: @escaping (_ result: SettingsSectionsProviderHandleActionCellResult) -> Void
            ) {
            
            switch cellIdentifier {
                
            case .tfa:
                self.handleTFAReload(
                    startLoading: startLoading,
                    stopLoading: stopLoading,
                    completion: completion
                )
                
            default:
                break
            }
        }
        
        func isTermsCell(cellIdentifier: Settings.CellIdentifier) -> Bool {
            return cellIdentifier == .termsOfService
        }
        
        // MARK: - Private
        
        private func updateSections() {
            self.sections.accept(self.createSections())
        }
        
        private func createSections() -> [Model.SectionModel] {
            let accountIdCell = Model.CellModel(
                title: Localized(.account_id),
                icon: Assets.verificationIcon.image,
                cellType: .disclosureCell,
                identifier: .accountId
            )
            
            let seedCell = Model.CellModel(
                title: Localized(.export_seed),
                icon: Assets.seed.image,
                cellType: .disclosureCell,
                identifier: .seed
            )
            
            let feesCell = Model.CellModel(
                title: Localized(.fees),
                icon: Assets.fee.image,
                cellType: .disclosureCell,
                identifier: .fees
            )
            
            let acountSection = Model.SectionModel(
                title: Localized(.account),
                cells: [accountIdCell, seedCell, feesCell],
                description: ""
            )
            
            let tfaCell = self.checkTFAEnabledState()
            
            let changePassCell = Model.CellModel(
                title: Localized(.change_password),
                icon: Assets.passwordIcon.image,
                cellType: .disclosureCell,
                identifier: .changePassword
            )
            
            var securityCells: [Model.CellModel] = [
                tfaCell,
                changePassCell
            ]
            
            let webClientAddress = self.apiConfigurationModel.webClient
            if webClientAddress != nil {
                let verificationCell = Model.CellModel(
                    title: Localized(.verification),
                    icon: Assets.verificationIcon.image,
                    cellType: .disclosureCell,
                    identifier: .verification
                )
                securityCells.insert(verificationCell, at: 1)
            }
            
            if let biometricsSettingInfo = self.getBiometricsSettingInfo() {
                let biometricsAuthCell = Model.CellModel(
                    title: biometricsSettingInfo.title,
                    icon: biometricsSettingInfo.icon,
                    cellType: .boolCell(biometricsSettingInfo.enabled),
                    identifier: .biometrics
                )
                securityCells.insert(biometricsAuthCell, at: 0)
            }
            
            let securitySection = Model.SectionModel(
                title: Localized(.security),
                cells: securityCells,
                description: ""
            )
            
            let termsCell = Model.CellModel(
                title: Localized(.terms_of_service),
                icon: Assets.documentIcon.image,
                cellType: .disclosureCell,
                identifier: .termsOfService
            )
            let licensesCell = Model.CellModel(
                title: Localized(.acknowledgements),
                icon: Assets.copyright.image,
                cellType: .disclosureCell,
                identifier: .licenses
            )
            
            let termsSection = Model.SectionModel(
                title: "",
                cells: [
                    termsCell,
                    licensesCell
                ],
                description: ""
            )
            
            let signOutCell = Model.CellModel(
                title: Localized(.sign_out),
                icon: Assets.signOutIcon.image,
                cellType: .disclosureCell,
                identifier: .signOut
            )
            
            let signOutSection = Model.SectionModel(
                title: "",
                cells: [signOutCell],
                description: ""
            )
            
            return [
                acountSection,
                securitySection,
                termsSection,
                signOutSection
            ]
        }
        
        private struct BiometricsSettingInfo {
            let title: String
            let icon: UIImage
            let enabled: Bool
        }
        
        private func getBiometricsSettingInfo() -> BiometricsSettingInfo? {
            let enabled: Bool = self.settingsManger.biometricsAuthEnabled
            
            let isTouchID: Bool
            let context = LAContext()
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
                if #available(iOS 11.0, *) {
                    let biometryType = context.biometryType
                    switch biometryType {
                        
                    case .faceID:
                        isTouchID = false
                        
                    case .none:
                        return nil
                        
                    case .touchID:
                        isTouchID = true
                    }
                } else {
                    isTouchID = true
                }
            } else {
                return nil
            }
            
            let title: String
            let icon: UIImage
            
            if isTouchID {
                title = Localized(.sign_in_with_touchid)
                icon = Assets.touchIdIcon.image
            } else {
                title = Localized(.sign_in_with_faceid)
                icon = Assets.faceIdIcon.image
            }
            
            return BiometricsSettingInfo(
                title: title,
                icon: icon,
                enabled: enabled
            )
        }
        
        private enum TFAEnabledState {
            case undetermined
            case loading
            case failed(Swift.Error)
            case loaded(enabled: Bool)
        }
        
        private func checkTFAEnabledState() -> Model.CellModel {
            let cellType: Model.CellModel.CellType
            
            switch self.tfaEnabledState {
                
            case .undetermined:
                self.loadTFAState()
                fallthrough
            case .loading:
                cellType = .loading
                
            case .failed:
                cellType = .reload
                
            case .loaded(let isEnabled):
                cellType = .boolCell(isEnabled)
            }
            
            let tfaCell = Model.CellModel(
                title: Localized(.twofactor_authentication),
                icon: Assets.securityIcon.image,
                cellType: cellType,
                identifier: .tfa
            )
            
            return tfaCell
        }
        
        private func loadTFAState() {
            self.updateTFAState { [weak self] in
                self?.updateSections()
            }
        }
        
        private func updateTFAState(
            _ completion: @escaping () -> Void
            ) {
            
            self.tfaEnabledState = .loading
            
            let walletId = self.userDataProvider.walletId
            self.tfaApi.getFactors(walletId: walletId, completion: { [weak self] result in
                switch result {
                    
                case .failure(let errors):
                    self?.tfaEnabledState = .failed(errors)
                    completion()
                    
                case .success(let factors):
                    let isEnabled = factors.isTOTPEnabled()
                    self?.tfaEnabledState = .loaded(enabled: isEnabled)
                    completion()
                }
            })
        }
        
        private func handleBiometricsEnabled(
            _ enabled: Bool,
            completion: @escaping (_ result: SettingsSectionsProviderHandleBoolCellResult) -> Void
            ) {
            
            self.settingsManger.biometricsAuthEnabled = enabled
            completion(.succeded)
            self.updateSections()
        }
        
        // MARK: - TFA TOTP
        
        enum HandleTFAReloadError: Swift.Error, LocalizedError {
            case failed(Swift.Error)
            case unsuitableStatus
            
            var errorDescription: String? {
                switch self {
                    
                case .failed(let error):
                    return error.localizedDescription
                    
                case .unsuitableStatus:
                    return Localized(.unsuitable_status)
                }
            }
        }
        private func handleTFAReload(
            startLoading: @escaping () -> Void,
            stopLoading: @escaping () -> Void,
            completion: @escaping (_ result: SettingsSectionsProviderHandleActionCellResult) -> Void
            ) {
            
            startLoading()
            
            self.updateTFAState { [weak self] in
                guard let strongSelf = self else { return }
                
                switch strongSelf.tfaEnabledState {
                    
                case .undetermined,
                     .loading:
                    stopLoading()
                    completion(.failed(HandleTFAReloadError.unsuitableStatus))
                    
                case .failed(let error):
                    stopLoading()
                    completion(.failed(HandleTFAReloadError.failed(error)))
                    
                case .loaded(let enabled):
                    self?.handleTFAEnabled(
                        !enabled,
                        startLoading: startLoading,
                        stopLoading: stopLoading,
                        completion: { (result) in
                            stopLoading()
                            
                            switch result {
                                
                            case .succeded:
                                completion(.succeeded)
                                
                            case .failed(let error):
                                completion(.failed(error))
                            }
                    })
                }
            }
        }
        
        private func handleTFAEnabled(
            _ enabled: Bool,
            startLoading: @escaping () -> Void,
            stopLoading: @escaping () -> Void,
            completion: @escaping (_ result: SettingsSectionsProviderHandleBoolCellResult) -> Void
            ) {
            
            startLoading()
            
            let walletId = self.userDataProvider.walletId
            self.deleteTOTPFactors(
                walletId: walletId,
                completion: { [weak self] (result) in
                    switch result {
                        
                    case .failure(let error):
                        self?.onTFAEnableFailed(
                            oldValue: !enabled,
                            error: error,
                            stopLoading: stopLoading,
                            completion: completion
                        )
                        
                    case .success:
                        if enabled {
                            self?.enableTOTPFactor(
                                walletId: walletId,
                                stopLoading: stopLoading,
                                completion: completion
                            )
                        } else {
                            self?.onTFAEnableSucceeded(
                                enabled: false,
                                stopLoading: stopLoading,
                                completion: completion
                            )
                        }
                    }
            })
        }
        
        private func enableTOTPFactor(
            walletId: String,
            stopLoading: @escaping () -> Void,
            completion: @escaping (_ result: SettingsSectionsProviderHandleBoolCellResult) -> Void
            ) {
            
            let createFactor: (_ priority: Int) -> Void = { [weak self] (priority) in
                self?.tfaApi.createFactor(
                    walletId: walletId,
                    type: TFAFactorType.totp.rawValue,
                    completion: { (result) in
                        switch result {
                            
                        case .failure(let error):
                            self?.onTFAEnableFailed(
                                oldValue: false,
                                error: error,
                                stopLoading: stopLoading,
                                completion: completion
                            )
                            
                        case .success(let response):
                            self?.showTOTPSetupDialog(
                                response: response,
                                walletId: walletId,
                                priority: priority,
                                stopLoading: stopLoading,
                                completion: completion
                            )
                        }
                })
            }
            
            self.tfaApi.getFactors(
                walletId: walletId,
                completion: { (result) in
                    switch result {
                        
                    case .failure(let errors):
                        stopLoading()
                        completion(.failed(errors))
                        
                    case .success(let factors):
                        let priority = factors.getHighestPriority(factorType: nil) + 1
                        createFactor(priority)
                    }
            })
        }
        
        private func updateTOTPFactor(
            walletId: String,
            factorId: Int,
            priority: Int,
            stopLoading: @escaping () -> Void,
            completion: @escaping (_ result: SettingsSectionsProviderHandleBoolCellResult) -> Void
            ) {
            
            self.tfaApi.updateFactor(
                walletId: walletId,
                factorId: factorId,
                priority: priority,
                completion: { [weak self] result in
                    switch result {
                        
                    case .failure(let error):
                        self?.onTFAEnableFailed(
                            oldValue: false,
                            error: error,
                            stopLoading: stopLoading,
                            completion: completion
                        )
                        
                    case .success:
                        self?.onTFAEnableSucceeded(
                            enabled: true,
                            stopLoading: stopLoading,
                            completion: completion
                        )
                    }
            })
        }
        
        enum DeleteTOTPFactorsResult {
            case failure(Swift.Error)
            case success
        }
        private func deleteTOTPFactors(
            walletId: String,
            completion: @escaping (_ result: DeleteTOTPFactorsResult) -> Void
            ) {
            
            self.tfaApi.getFactors(
                walletId: walletId,
                completion: { [weak self] (result) in
                    switch result {
                        
                    case .failure(let errors):
                        completion(.failure(errors))
                        
                    case .success(let factors):
                        let totpFactors = factors.getTOTPFactors()
                        if let totpFactor = totpFactors.first {
                            self?.tfaApi.deleteFactor(
                                walletId: walletId,
                                factorId: totpFactor.id,
                                completion: { (deleteResult) in
                                    switch deleteResult {
                                        
                                    case .failure(let error):
                                        completion(.failure(error))
                                        
                                    case .success:
                                        self?.deleteTOTPFactors(walletId: walletId, completion: completion)
                                    }
                            })
                        } else {
                            completion(.success)
                        }
                    }
            })
        }
        
        private func showTOTPSetupDialog(
            response: TFACreateFactorResponse,
            walletId: String,
            priority: Int,
            stopLoading: @escaping () -> Void,
            completion: @escaping (_ result: SettingsSectionsProviderHandleBoolCellResult) -> Void
            ) {
            
            let secret = response.attributes.secret
            let alert = UIAlertController(
                title: Localized(.set_up_2fa),
                message: Localized(
                    .to_enable_twofactor_authentication,
                    replace: [
                        .to_enable_twofactor_authentication_replace_secret: secret
                    ]
                ),
                preferredStyle: .alert
            )
            // swiftlint:enable line_length
            
            alert.addAction(UIAlertAction(
                title: Localized(.copy),
                style: .default,
                handler: { [weak self] _ in
                    UIPasteboard.general.string = response.attributes.secret
                    
                    self?.updateTOTPFactor(
                        walletId: walletId,
                        factorId: response.id,
                        priority: priority,
                        stopLoading: stopLoading,
                        completion: completion
                    )
            }))
            
            if let url = URL(string: response.attributes.seed),
                UIApplication.shared.canOpenURL(url) {
                alert.addAction(UIAlertAction(
                    title: Localized(.open_app),
                    style: .default,
                    handler: { [weak self] _ in
                        UIPasteboard.general.string = response.attributes.secret
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        
                        self?.updateTOTPFactor(
                            walletId: walletId,
                            factorId: response.id,
                            priority: priority,
                            stopLoading: stopLoading,
                            completion: completion
                        )
                }))
            }
            
            alert.addAction(UIAlertAction(
                title: Localized(.cancel),
                style: .cancel,
                handler: { [weak self] _ in
                    self?.onTFAEnableSucceeded(
                        enabled: false,
                        stopLoading: stopLoading,
                        completion: completion
                    )
            }))
            
            self.onPresentAlert(alert)
        }
        
        private func onTFAEnableFailed(
            oldValue: Bool,
            error: Swift.Error,
            stopLoading: @escaping () -> Void,
            completion: @escaping (_ result: SettingsSectionsProviderHandleBoolCellResult) -> Void
            ) {
            
            stopLoading()
            self.tfaEnabledState = .failed(error)
            completion(.failed(error))
            self.updateSections()
        }
        
        private func onTFAEnableSucceeded(
            enabled: Bool,
            stopLoading: @escaping () -> Void,
            completion: @escaping (_ result: SettingsSectionsProviderHandleBoolCellResult) -> Void
            ) {
            
            stopLoading()
            self.tfaEnabledState = .loaded(enabled: enabled)
            completion(.succeded)
            self.updateSections()
        }
    }
    // swiftlint:enable type_body_length
}
