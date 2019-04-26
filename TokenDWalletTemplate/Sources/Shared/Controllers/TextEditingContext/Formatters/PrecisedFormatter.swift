import UIKit

class PrecisedFormatter: DecimalFormatter {
    
    public static var precision: Int64 = 1_000_000
    
    override func valueFromString(_ string: String?) -> Decimal? {
        guard let value = super.valueFromString(string) else {
            return nil
        }
        
        let multiplied = NSDecimalNumber(
            decimal: value * Decimal(PrecisedFormatter.precision)
        )
        let rounded = multiplied.rounding(
            accordingToBehavior: DecimalFloorRoundingBehavior()
        )
        
        let diff = multiplied.decimalValue - rounded.decimalValue
        
        return diff == 0 ? value : nil
    }
}
