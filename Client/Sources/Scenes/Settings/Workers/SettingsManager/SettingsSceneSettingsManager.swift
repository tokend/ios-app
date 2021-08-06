import Foundation

extension SettingsScene {
    
    class SettingsManager {
        
        // MARK: - Private properties
        
        private let settingsManager: Client.SettingsManagerProtocol
        
        // MARK: -
        
        init (
            settingsManager: Client.SettingsManagerProtocol
        ) {
            self.settingsManager = settingsManager
        }
    }
}

extension SettingsScene.SettingsManager: SettingsScene.SettingsManagerProtocol {
    var biometricsAuthEnabled: Bool {
        get { self.settingsManager.biometricsAuthEnabled }
        set { self.settingsManager.biometricsAuthEnabled = newValue }
    }
}
