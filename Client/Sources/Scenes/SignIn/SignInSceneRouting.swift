import Foundation

extension SignInScene {
    
    public struct Routing {
        
//        public let onBackAction: () -> Void
        public let onSelectNetwork: (_ completion: (String) -> Void) -> Void
        public let onForgotPassword: () -> Void
        public let onSignUp: () -> Void
    }
}
