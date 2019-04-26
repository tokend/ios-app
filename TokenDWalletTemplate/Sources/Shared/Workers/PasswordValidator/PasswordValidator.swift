import Foundation

public enum PasswordValidatorResult {
    case success
    case error(String)
}
protocol PasswordValidatorProtocol {
    func validate(password: String) -> PasswordValidatorResult
}

public class PasswordValidator: PasswordValidatorProtocol {
    
    // MARK: - Private properties
    
    private let minimalLength: Int = 6
    
    // MARK: - PasswordValidatorProtocol
    
    func validate(password: String) -> PasswordValidatorResult {
        if password.count >= minimalLength {
            return .success
        } else {
            let errorMessage = Localized(
                .password_should_contain_at_least_characters,
                replace: [
                    .password_should_contain_at_least_characters_replace_minimal_length: "\(self.minimalLength)"
                ]
            )
            return .error(errorMessage)
        }
    }
}
