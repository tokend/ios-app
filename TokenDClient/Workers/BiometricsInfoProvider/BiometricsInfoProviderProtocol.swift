import Foundation

public enum BiometricsType {

    case faceId
    case touchId
    case none
}

public protocol BiometricsInfoProviderProtocol {

    var biometricsType: BiometricsType { get }
    var isAvailable: Bool { get }
}
