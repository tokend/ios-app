import Foundation

extension ChangePasswordScene {
    
    public struct Routing {
        
        public let onBackAction: () -> Void
        public let onChangePassword: (_ currentPassword: String, _ newPassword: String) -> Void
    }
}
