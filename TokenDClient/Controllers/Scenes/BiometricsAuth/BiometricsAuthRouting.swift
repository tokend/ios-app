import Foundation

extension BiometricsAuth {
    struct Routing {
        let onAuthSucceeded: (_ account: String) -> Void
        let onAuthFailed: () -> Void
        let onUserCancelled: () -> Void
        let onUserFallback: () -> Void
    }
}
