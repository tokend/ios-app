import Foundation

protocol SettingsManagerProtocol: class {
    var biometricsAuthEnabled: Bool { get set }
}

class SettingsManager {
    
    // MARK: - Public properties
    
    static let biometricsAuthEnabledUserDefaultsKey: String = "biometricsAuthEnabled"
    
    var biometricsAuthEnabled: Bool {
        get {
            return self.getBiometricsAuthEnabled()
        }
        set {
            self.setBiometricsAuthEnabled(newValue)
        }
    }
    
    // MARK: - Private properties
    
    let userDefaults: UserDefaults = UserDefaults.standard
    
    // MARK: -
    
    init() {
        
    }
    
    // MARK: - Private
    
    private func getBiometricsAuthEnabled() -> Bool {
        guard self.userDefaults.object(forKey: SettingsManager.biometricsAuthEnabledUserDefaultsKey) != nil else {
            // Biometrics are enabled by default
            return true
        }
        
        return self.userDefaults.bool(forKey: SettingsManager.biometricsAuthEnabledUserDefaultsKey)
    }
    
    private func setBiometricsAuthEnabled(_ enabled: Bool) {
        self.userDefaults.set(enabled, forKey: SettingsManager.biometricsAuthEnabledUserDefaultsKey)
    }
}

extension SettingsManager: SettingsManagerProtocol {}
