import UIKit

public class NewAmountFormatter: NSObject {

    public typealias TrailingDigits = Int

    public static let shared: NewAmountFormatter = .init()

    // MARK: - Private properties

    private var numberFormatters: [TrailingDigits: NumberFormatter] = [:]
    private var keyboardNumberFormatters: [TrailingDigits: NumberFormatter] = [:]

    // MARK: - Public methods

    public func formatAmount(
        _ amount: Decimal,
        currency: String,
        trailingDigits: TrailingDigits
    ) -> String {

        [amountToString(amount, trailingDigits: trailingDigits), currency].joined(separator: " ")
    }

    public func formatReversedAmount(
        _ amount: Decimal,
        currency: String,
        trailingDigits: TrailingDigits
    ) -> String {

        [currency, amountToString(amount, trailingDigits: trailingDigits)].joined(separator: " ")
    }

    public func amountToString(
        _ amount: Decimal,
        trailingDigits: TrailingDigits
    ) -> String {

        if let numberFormatter = numberFormatters[trailingDigits] {
            return numberFormatter.string(from: amount) ?? "\(amount)"
        }

        let formatter =  self.createNumberFormatter(maxFractionDigits: trailingDigits)
        formatter.minimumFractionDigits = 1
        numberFormatters[trailingDigits] = formatter

        return amountToString(amount, trailingDigits: trailingDigits)
    }

    public func keyboardNumberFormatter(
        trailingDigits: TrailingDigits
    ) -> NumberFormatter {

        if let formatter = keyboardNumberFormatters[trailingDigits] {
            return formatter
        }

        let formatter = createNumberFormatter(maxFractionDigits: trailingDigits)
        formatter.usesGroupingSeparator = false
        keyboardNumberFormatters[trailingDigits] = formatter
        return keyboardNumberFormatter(trailingDigits: trailingDigits)
    }
}

// MARK: - Private methods

private extension NewAmountFormatter {

    func createNumberFormatter(
        maxFractionDigits: TrailingDigits
    ) -> NumberFormatter {

        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = true
        formatter.decimalSeparator = "."
        formatter.groupingSeparator = ","
        formatter.numberStyle = .decimal
        formatter.maximumIntegerDigits = 30
        formatter.maximumFractionDigits = maxFractionDigits
        formatter.roundingMode = .halfDown
        formatter.minimumIntegerDigits = 1

        return formatter
    }
}
