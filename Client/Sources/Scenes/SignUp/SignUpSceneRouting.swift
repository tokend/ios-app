import Foundation

extension SignUpScene {
    
    public struct Routing {
        
        public typealias OnCreateAccount = (
            _ email: String,
            _ password: String
        ) -> Void
        
        public let onBackAction: () -> Void
        public let onSelectNetwork: () -> Void
        public let onCreateAccount: OnCreateAccount
    }
}
