import Foundation

extension String {

    func convertToPhoneNumber() -> String {
        replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
    }
    
    func isValidPhoneNumber() -> Bool {
        let phoneNumberRegex: String = "^[+][0-9]{5,14}$"
        
        let result = NSPredicate(format: "SELF MATCHES %@", phoneNumberRegex)
        
        return result.evaluate(with: self)
    }
}
