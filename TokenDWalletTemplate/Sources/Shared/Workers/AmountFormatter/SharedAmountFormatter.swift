import UIKit

public class SharedAmountFormatter: NSObject {
    
    // TODO: Refactor
    public static var maxFractionDigits: Int = 6
    
    // MARK: - Private properties
    
    private lazy var assetNumberFormatter: NumberFormatter = {
        return self.createNumberFormatter()
    }()
    
    private lazy var fiatNumberFormatter: NumberFormatter = {
        return self.createNumberFormatter(maxFractionDigits: 2)
    }()
    
    private let fiatCurrencies: [String] = ["USD", "EUR"]
    
    // MARK: - Public
    
    public func formatAmount(_ amount: Decimal, currency: String) -> String {
        return [self.suffixDecimal(amount, currency: currency), " ", currency].joined()
    }
    
    public func assetAmountToString(_ amount: Decimal) -> String {
        self.assetNumberFormatter.maximumFractionDigits = SharedAmountFormatter.maxFractionDigits
        return self.assetNumberFormatter.string(from: amount) ?? "\(amount)"
    }
    
    public func assetAmountToString(_ amount: Decimal, currency: String) -> String {
        return self.suffixDecimal(amount, currency: currency)
    }
    
    public func percentToString(value: Decimal) -> String {
        self.assetNumberFormatter.maximumFractionDigits = SharedAmountFormatter.maxFractionDigits
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
            let formatted = numberFormatter.string(from: decimal)
            return formatted ?? "\(decimal)"
        }
        
        let num = NSDecimalNumber(decimal: decimal).doubleValue
        let exp: Int = Int(log10(abs(num)) / 3.0 )
        
        let units: [String] = ["K", "M", "G", "T", "P", "E"]
        let multiplier: Double = pow(10.0, 2)
        
        let roundedNumber: Double = round(multiplier * num / pow(1000.0, Double(exp))) / multiplier
        let decimalRoundedNumber: Decimal = Decimal(roundedNumber)
        
        let formatted = numberFormatter.string(from: decimalRoundedNumber)
        return (formatted ?? "\(decimalRoundedNumber)") + "\(units[exp-1])"
    }
    
    private func createNumberFormatter(maxFractionDigits: Int? = nil) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = true
        formatter.decimalSeparator = "."
        formatter.groupingSeparator = ","
        formatter.numberStyle = .decimal
        formatter.maximumIntegerDigits = 30
        formatter.maximumFractionDigits =
            maxFractionDigits ?? SharedAmountFormatter.maxFractionDigits
        formatter.roundingMode = .halfDown
        formatter.minimumIntegerDigits = 1
        
        return formatter
    }
}
