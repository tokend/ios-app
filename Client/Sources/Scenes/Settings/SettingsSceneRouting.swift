import Foundation

extension SettingsScene {
    
    public struct Routing {
        
        public let onBackAction: () -> Void
        public let onLanguageTap: () -> Void
        public let onAccountIdTap: () -> Void
        public let onVerificationTap: () -> Void
        public let onSecretSeedTap: () -> Void
        public let onSignOutTap: () -> Void
        public let onChangePasswordTap: () -> Void
        public let onShowError: (Swift.Error) -> Void
    }
}
