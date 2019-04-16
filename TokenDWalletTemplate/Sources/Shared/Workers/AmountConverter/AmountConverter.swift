import UIKit

protocol AmountConverterProtocol {
    func convertDecimalToUInt64(value: Decimal, precision: Int64) -> UInt64
    func convertDecimalToInt64(value: Decimal, precision: Int64) -> Int64
}

public class AmountConverter: AmountConverterProtocol {
    
    // MARK: - Private proverties
    
    private let behavior: NSDecimalNumberBehaviors = DecimalFloorRoundingBehavior()
    
    // MARK: - AmountConverterProtocol
    
    func convertDecimalToUInt64(value: Decimal, precision: Int64) -> UInt64 {
        let amount = NSDecimalNumber(decimal: value * Decimal(precision)).rounding(accordingToBehavior: self.behavior)
        return UInt64(exactly: amount) ?? 0
    }
    
    func convertDecimalToInt64(value: Decimal, precision: Int64) -> Int64 {
        let amount = NSDecimalNumber(decimal: value * Decimal(precision)).rounding(accordingToBehavior: self.behavior)
        return Int64(exactly: amount) ?? 0
    }
}
