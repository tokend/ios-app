import UIKit

class DecimalFormatter: ValueFormatter<Decimal> {
    
    // TODO: Refactor
    public static var precision: Int = 6
    
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = false
        formatter.decimalSeparator = "."
        formatter.numberStyle = .decimal
        formatter.maximumIntegerDigits = 30
        formatter.maximumFractionDigits = DecimalFormatter.precision
        formatter.roundingMode = .halfUp
        formatter.minimumIntegerDigits = 1
        return formatter
    }()
    var emptyZeroValue: Bool = false
    let invalidCharSet = CharacterSet(charactersIn: "1234567890.").inverted
    
    override func stringFromValue(_ value: Decimal?) -> String? {
        if let valueDecimal = value {
            if valueDecimal == 0 && self.emptyZeroValue {
                return ""
            }
            self.numberFormatter.maximumFractionDigits = DecimalFormatter.precision
            return self.numberFormatter.string(from: valueDecimal)
        } else {
            return nil
        }
    }
    
    override func valueFromString(_ string: String?) -> Decimal? {
        let invalidCharsRange = string?.rangeOfCharacter(from: self.invalidCharSet)
        if invalidCharsRange != nil {
            return nil
        }
        
        if let valueString = string {
            let valueDecimal = Decimal(string: valueString)
            return valueDecimal
        } else {
            return nil
        }
    }
}
