import Foundation

extension SignInScene {
    
    public struct Routing {
        
        public let onSignIn: (_ login: String, _ password: String) -> Void
        public let onSelectNetwork: () -> Void
        public let onForgotPassword: () -> Void
        public let onSignUp: () -> Void
    }
}
