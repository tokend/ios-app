import Foundation
import RxSwift

extension SettingsScene {
    
    class TFAManager {
        
        // MARK: - Private properties

        private let tfaManager: Client.TFAManagerProtocol
        
        // MARK: -
        
        init(
            tfaManager: Client.TFAManagerProtocol
        ) {
            
            self.tfaManager = tfaManager
        }
    }
}

extension SettingsScene.TFAManager: SettingsScene.TFAManagerProtocol {
    var state: SettingsScene.Model.TFAState {
        self.tfaManager.status.mapToTFAState()
    }
    
    func observeTfaState() -> Observable<SettingsScene.Model.TFAState> {
        return self.tfaManager.observeTfaStatus().map { (status) -> SettingsScene.Model.TFAState in
            return status.mapToTFAState()
        }
    }
    
    func disableTFA(completion: @escaping (Result<Void, Error>) -> Void) {
        tfaManager.disableTFA(completion: completion)
    }
    
    func enableTFA(completion: @escaping (Result<Void, Error>) -> Void) {
        tfaManager.enableTFA(completion: completion)
    }
}

private extension TFAStatus {
    
    func mapToTFAState() -> SettingsScene.Model.TFAState {
        
        switch self {
        
        case .undetermined:
            return .undetermined
        case .loading:
            return .loading
        case .failed:
            return .failed
        case .loaded(enabled: let enabled):
            return .loaded(enabled: enabled)
        }
    }
}
