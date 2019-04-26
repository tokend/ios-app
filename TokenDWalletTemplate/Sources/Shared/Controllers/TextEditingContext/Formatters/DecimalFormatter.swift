import UIKit

class DecimalFormatter: ValueFormatter<Decimal> {
    
    // TODO: Refactor
    public static var maxFractionDigits: Int = 6 {
        didSet {
            self.numberFormatter.maximumFractionDigits = self.maxFractionDigits
        }
    }
    
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = false
        formatter.decimalSeparator = "."
        formatter.numberStyle = .decimal
        formatter.maximumIntegerDigits = 30
        formatter.maximumFractionDigits = DecimalFormatter.maxFractionDigits
        formatter.roundingMode = .halfUp
        formatter.minimumIntegerDigits = 1
        return formatter
    }()
    var emptyZeroValue: Bool = false
    let digits: String = "1234567890"
    let decimalSeparator: String = "."
    lazy var invalidCharSet: CharacterSet = {
        return CharacterSet(charactersIn: "\(self.digits)\(self.decimalSeparator)").inverted
    }()
    
    override func stringFromValue(_ value: Decimal?) -> String? {
        if let valueDecimal = value {
            if valueDecimal == 0 && self.emptyZeroValue {
                return ""
            }
            return DecimalFormatter.numberFormatter.string(from: valueDecimal)
        } else {
            return nil
        }
    }
    
    override func valueFromString(_ string: String?) -> Decimal? {
        guard let string = string else {
            return nil
        }
        
        let invalidCharsRange = string.rangeOfCharacter(from: self.invalidCharSet)
        if invalidCharsRange != nil {
            return nil
        }
        
        let decimalSeparatorCheck = string
            .components(separatedBy: self.decimalSeparator)
            .count <= 2
        
        guard decimalSeparatorCheck else {
            return nil
        }
        
        let valueDecimal = Decimal(string: string)
        return valueDecimal
    }
}
