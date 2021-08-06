import Foundation

public protocol SettingsSceneSettingsManagerProtocol: AnyObject {
    
    var biometricsAuthEnabled: Bool { get set }
}

extension SettingsScene {
    
    public typealias SettingsManagerProtocol = SettingsSceneSettingsManagerProtocol
}
