import UIKit

protocol AmountConverterProtocol {
    func convertDecimalToUInt64(value: Decimal, precision: Int) -> UInt64
    func convertDecimalToInt64(value: Decimal, precision: Int) -> Int64
}

public class AmountConverter: AmountConverterProtocol {
    func convertDecimalToUInt64(value: Decimal, precision: Int) -> UInt64 {
        let amount = NSDecimalNumber(decimal: value * pow(10, precision))
        return UInt64(exactly: amount) ?? 0
    }
    
    func convertDecimalToInt64(value: Decimal, precision: Int) -> Int64 {
        let amount = NSDecimalNumber(decimal: value * pow(10, precision))
        return Int64(exactly: amount) ?? 0
    }
}
