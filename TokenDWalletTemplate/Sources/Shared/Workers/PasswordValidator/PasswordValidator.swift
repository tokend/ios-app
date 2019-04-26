import Foundation

public class PasswordValidator {
    public static let minimalLength: Int = 6
    
    public static func canBePassword(password: String) -> Bool {
        return password.count >= minimalLength
    }
}
