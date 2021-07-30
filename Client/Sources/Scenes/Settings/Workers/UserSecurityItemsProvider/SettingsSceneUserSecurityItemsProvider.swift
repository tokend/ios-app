//import Foundation
//import RxSwift
//import RxCocoa
//
//extension SettingsScene {
//    
//    class SecurityItemsProvider {
//        
//        typealias OnTransition = (TransitionItem) -> Void
//
//        enum TransitionItem: String {
//            case changePasscode
//            
//            var id: String {
//                rawValue
//            }
//            
//            init?(id: String) {
//                self.init(rawValue: id)
//            }
//        }
//        
//        enum SwitchItem: String {
//            case lockApp
//            case biometrics
//            case tfa
//            
//            var id: String {
//                rawValue
//            }
//            
//            init?(id: String) {
//                self.init(rawValue: id)
//            }
//        }
//        
//        private let onTransition: OnTransition
//        private let settingsManager: SettingsManagerProtocol
//        private let tfaManager: TFAManagerProtocol
//        private let biometricsProvider: BiometricsInfoProviderProtocol
//        private let securitySectionBehaviorRelay: BehaviorRelay<[SettingsScene.Model.SecurityTab]> = .init(value: [])
//        
//        private let disposeBag: DisposeBag = .init()
//        
//        private var shouldObserveTfa: Bool = true
//
//        init(
//            settingsManager: SettingsManagerProtocol,
//            tfaManager: TFAManagerProtocol,
//            biometricsProvider: BiometricsInfoProviderProtocol,
//            onTransition: @escaping OnTransition
//        ) {
//            self.settingsManager = settingsManager
//            self.tfaManager = tfaManager
//            self.biometricsProvider = biometricsProvider
//            self.onTransition = onTransition
//        }
//    }
//}
//
//extension SettingsScene.SecurityItemsProvider: SettingsScene.SecurityItemsProviderProtocol {
//    
//    var securitySection: [SettingsScene.Model.SecurityTab] {
//        securitySectionBehaviorRelay.value
//    }
//    
//    func observeSecuritySection() -> Observable<[SettingsScene.Model.SecurityTab]> {
//        if shouldObserveTfa {
//            shouldObserveTfa = false
//            observeTfaStatus()
//            createSections()
//        }
//        return securitySectionBehaviorRelay.asObservable()
//    }
//    
//    func transition(to id: String) {
//        guard let item = TransitionItem(id: id)
//        else {
//            return
//        }
//        
//        onTransition(item)
//    }
//    
//    func switcherValueChanged(
//        in id: String,
//        to value: Bool,
//        completion: @escaping (Result<Void, Swift.Error>) -> Void
//    ) {
//        
//        guard let switcher = SwitchItem(id: id)
//        else {
//            return
//        }
//        
//        switch switcher {
//        
//        case .lockApp:
//            // TODO: - Implement
//            break
//            
//        case .biometrics:
//            settingsManager.biometricsAuthEnabled = value
//            createSections()
//            completion(.success(()))
//            
//        case .tfa:
//            changeTfaValue(
//                to: value,
//                completion: completion
//            )
//        }
//    }
//}
//
//private extension SettingsScene.SecurityItemsProvider {
//    
//    func observeTfaStatus() {
//        tfaManager
//            .observeTfaStatus()
//            .subscribe(onNext: { [weak self] (status) in
//                self?.createSections()
//            })
//            .disposed(by: disposeBag)
//    }
//    
//    func createSections() {
//        
//        var securitySection: [SettingsScene.Model.SecurityTab] = []
//        
//        securitySection.append(
//            SettingsScene.Model.SecurityTab(
//                id: TransitionItem.changePasscode.id,
//                type: .transition,
//                title: TransitionItem.changePasscode.name
//            )
//        )
//        
//        if biometricsProvider.isAvailable {
//            securitySection.append(
//                SettingsScene.Model.SecurityTab(
//                    id: SwitchItem.biometrics.id,
//                    type: .switcher(isOn: settingsManager.biometricsAuthEnabled),
//                    title: biometricsProvider.biometricsType.name
//                )
//            )
//        }
//        
//        switch tfaManager.status {
//        
//        case .undetermined:
//            break
//        case .loading:
//            break
//        case .failed(_):
//            break
//        case .loaded(enabled: let enabled):
//            securitySection.append(
//                SettingsScene.Model.SecurityTab(
//                    id: SwitchItem.tfa.id,
//                    type: .switcher(isOn: enabled),
//                    title: Localized(.settings_security_tfa)
//                )
//            )
//        }
//        
//        securitySectionBehaviorRelay.accept(securitySection)
//    }
//    
//    func changeTfaValue(
//        to newValue: Bool,
//        completion: @escaping (Result<Void, Swift.Error>) -> Void
//    ) {
//        
//        if newValue {
//            tfaManager.enableTFA(completion: completion)
//        } else {
//            tfaManager.disableTFA(completion: completion)
//        }
//    }
//}
//
//private extension SettingsScene.SecurityItemsProvider.TransitionItem {
//    
//    var name: String {
//        
//        switch self {
//        
//        case .changePasscode:
//            return Localized(.settings_security_change_password)
//        }
//    }
//}
//
//private extension BiometricsType {
//    
//    var name: String {
//        
//        switch self {
//        
//        case .faceId:
//            return Localized(.face_id_title)
//        case .touchId:
//            return Localized(.touch_id_title)
//        case .none:
//            return ""
//        }
//    }
//}
