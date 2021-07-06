import Foundation

extension String {
    
    func removeSpaces() -> String {
        return self.replacingOccurrences(of: " ", with: "")
    }
}
