import Foundation

extension String {
    
    func validateEmail() -> Bool {
        
        let emailRegex: String = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        
        let result = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        return result.evaluate(with: self)
    }
}
