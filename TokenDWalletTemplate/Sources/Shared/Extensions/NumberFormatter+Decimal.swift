import Foundation

extension NumberFormatter {
    
    func string(from: Decimal) -> String? {
        return string(from: NSDecimalNumber(decimal: from))
    }
    
    func decimal(from: String) -> Decimal? {
        return self.number(from: from)?.decimalValue
    }
}
