import Foundation
import RxSwift

public protocol SettingsSceneTFAManagerProtocol {
    
    var state: SettingsScene.Model.TFAState { get }
    
    func observeTfaState(
    ) -> Observable<SettingsScene.Model.TFAState>
    
    func enableTFA(
        completion: @escaping (Swift.Result<Void, Swift.Error>) -> Void
    )
    
    func disableTFA(
        completion: @escaping (Swift.Result<Void, Swift.Error>) -> Void
    )
}

extension SettingsScene {
    public typealias TFAManagerProtocol = SettingsSceneTFAManagerProtocol
}
