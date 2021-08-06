import Foundation

extension SettingsScene {
    
    class BiometricsInfoProvider {
        
        // MARK: - Private properties
        
        private let biometricsInfoProvider: Client.BiometricsInfoProviderProtocol
        
        // MARK: -
        
        init(
            biometricsInfoProvider: Client.BiometricsInfoProviderProtocol
        ) {
            self.biometricsInfoProvider = biometricsInfoProvider
        }
    }
}

extension SettingsScene.BiometricsInfoProvider: SettingsScene.BiometricsInfoProviderProtocol {
    
    var biometricsType: SettingsScene.Model.BiometricsType {
        return self.biometricsInfoProvider.biometricsType.mapToBiometricsType()
    }
    
    var isAvailable: Bool {
        return self.biometricsInfoProvider.isAvailable
    }
}

private extension BiometricsType {
    
    func mapToBiometricsType() -> SettingsScene.Model.BiometricsType {
        
        switch self {
        
        case .faceId:
            return .faceId
        case .touchId:
            return .touchId
        case .none:
            return .none
        }
    }
}
