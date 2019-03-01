import UIKit

protocol AuthAppAvailibilityCheckerProtocol {
    func isAppAvailable() -> Bool
}

extension AuthenticatorAuth {
    
    class AuthAppAvailibilityChecker {
        
        // MARK: - Private properties
        
        private let scheme: String = "tokend://auth"
    }
}

extension AuthenticatorAuth.AuthAppAvailibilityChecker: AuthAppAvailibilityCheckerProtocol {
    
    func isAppAvailable() -> Bool {
        guard let urlSceme = URL(string: self.scheme) else {
            return false
        }
        
        return UIApplication.shared.canOpenURL(urlSceme)
    }
}
