import Foundation

extension LocalSignInScene {
    
    public struct Routing {
        public let onBiometrics: () -> Void
        public let onForgotPassword: () -> Void
        public let onSignOut: () -> Void
        public let onSignIn: (_ password: String) -> Void
    }
}
