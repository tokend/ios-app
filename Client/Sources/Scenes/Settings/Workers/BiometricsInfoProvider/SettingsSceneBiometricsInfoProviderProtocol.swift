import Foundation

public protocol SettingsSceneBiometricsInfoProviderProtocol {
    
    var biometricsType: SettingsScene.Model.BiometricsType { get }
    var isAvailable: Bool { get }
}

extension SettingsScene {
    public typealias BiometricsInfoProviderProtocol = SettingsSceneBiometricsInfoProviderProtocol
}
