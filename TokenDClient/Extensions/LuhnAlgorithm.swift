import Foundation

private func luhnCheck(number: String) -> Bool {
    var sum = 0
    let digitStrings = number.reversed().map { String($0) }
    
    for tuple in digitStrings.enumerated() {
        if let digit = Int(tuple.element) {
            let odd = tuple.offset % 2 == 1
            
            switch (odd, digit) {
            case (true, 9):
                sum += 9
            case (true, 0...8):
                sum += (digit * 2) % 9
            default:
                sum += digit
            }
        } else {
            return false
        }
    }
    
    return sum % 10 == 0
}

extension String {
    var isValidCreditCard: Bool {
        let number = self.replacingOccurrences(of: " ", with: "")
        return number.count == 16 && luhnCheck(number: number)
    }
}
