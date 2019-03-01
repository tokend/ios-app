import UIKit

protocol AmountConverterProtocol {
    func convertDecimalToUInt64(value: Decimal, precision: Int64) -> UInt64
    func convertDecimalToInt64(value: Decimal, precision: Int64) -> Int64
}

public class AmountConverter: AmountConverterProtocol {
    func convertDecimalToUInt64(value: Decimal, precision: Int64) -> UInt64 {
        let amount = NSDecimalNumber(decimal: value * Decimal(precision))
        return UInt64(exactly: amount) ?? 0
    }
    
    func convertDecimalToInt64(value: Decimal, precision: Int64) -> Int64 {
        let amount = NSDecimalNumber(decimal: value * Decimal(precision))
        return Int64(exactly: amount) ?? 0
    }
}
