import Foundation

class AmountFormatter {
    
    // MARK: - Private properties
    
    private let numberFormatter: NumberFormatter = .init()
    
    // MARK: -
    
    init() {
        
    }
}

// MARK: - Private methods

private extension AmountFormatter {
    
    func setupNumberFormatter() {
        numberFormatter.minimumFractionDigits = 1
        numberFormatter.maximumFractionDigits = 8
        numberFormatter.minimumIntegerDigits = 1
        numberFormatter.usesGroupingSeparator = false
        // FIXME: - Use local decimal separator?
        numberFormatter.decimalSeparator = NumberFormatter().decimalSeparator ?? Locale.current.decimalSeparator ?? "."
    }
}

// MARK: - AmountFormatterProtocol

//extension AmountFormatter: AmountFormatterProtocol {
//
//    func format(_ amount: Decimal) -> String {
//        return numberFormatter.string(from: amount)
//    }
//}
