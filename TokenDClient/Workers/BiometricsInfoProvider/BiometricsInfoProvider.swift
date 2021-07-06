import Foundation
import LocalAuthentication

class BiometricsInfoProvider: BiometricsInfoProviderProtocol {

    // MARK: - Private properties

    private let policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics

    // MARK: - Public properties

    private(set) lazy var biometricsType: BiometricsType = {
        let context = LAContext()
        if context.canEvaluatePolicy(self.policy, error: nil) {

            if #available(iOS 11.0, *) {
                switch context.biometryType {

                case .faceID:
                    return .faceId

                case .touchID:
                    return .touchId

                case .none:
                    return .none

                @unknown default:
                    return .none
                }
            } else {

                return .touchId
            }
        }
        return .none
    }()

    var isAvailable: Bool {
        let context = LAContext()
        let error: NSErrorPointer = nil
        if context.canEvaluatePolicy(self.policy, error: error) {
            return error?.pointee == nil
        }
        return false
    }
}
