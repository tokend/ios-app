import UIKit

class SharedAmountFormatter {
    
    // MARK: - Private properties
    
    private lazy var assetNumberFormatter: NumberFormatter = {
        return self.createNumberFormatter(maximumFractionDigits: 6)
    }()
    
    private lazy var fiatNumberFormatter: NumberFormatter = {
        return self.createNumberFormatter(maximumFractionDigits: 2)
    }()
    
    private let fiatCurrencies: [String] = ["USD", "EUR"]
    
    // MARK: - Public
    
    func formatAmount(_ amount: Decimal, currency: String) -> String {
        return [self.suffixDecimal(amount, currency: currency), " ", currency].joined()
    }
    
    func assetAmountToString(_ amount: Decimal) -> String {
        return self.assetNumberFormatter.string(from: amount) ?? "\(amount)"
    }
    
    func percentToString(value: Decimal) -> String {
        return self.assetNumberFormatter.string(from: value) ?? "\(value)"
    }
    
    // MARK: - Private
    
    private func suffixDecimal(
        _ decimal: Decimal,
        currency: String
        ) -> String {
        
        let numberFormatter: NumberFormatter
        if self.fiatCurrencies.contains(currency.uppercased()) {
            numberFormatter = self.fiatNumberFormatter
        } else {
            numberFormatter = self.assetNumberFormatter
        }
        
        if abs(decimal) < 1000 {
            return numberFormatter.string(from: decimal) ?? "\(decimal)"
        }
        
        let num = NSDecimalNumber(decimal: decimal).doubleValue
        let exp: Int = Int(log10(abs(num)) / 3.0 )
        
        let units: [String] = ["K", "M", "G", "T", "P", "E"]
        let multiplier: Double = pow(10.0, 2)
        
        let roundedNumber: Double = round(multiplier * num / pow(1000.0, Double(exp))) / multiplier
        let decimalRoundedNumber: Decimal = Decimal(roundedNumber)
        
        return (numberFormatter.string(from: decimalRoundedNumber) ?? "\(decimalRoundedNumber)") + "\(units[exp-1])"
    }
    
    private func createNumberFormatter(maximumFractionDigits: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = true
        formatter.decimalSeparator = "."
        formatter.groupingSeparator = ","
        formatter.numberStyle = .decimal
        formatter.maximumIntegerDigits = 30
        formatter.maximumFractionDigits = maximumFractionDigits
        formatter.roundingMode = .halfDown
        formatter.minimumIntegerDigits = 1
        
        return formatter
    }
}
