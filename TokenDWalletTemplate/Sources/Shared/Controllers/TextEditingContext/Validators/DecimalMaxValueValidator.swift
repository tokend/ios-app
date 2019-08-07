import Foundation

class DecimalMaxValueValidator: ValueValidator <Decimal> {
    
    // MARK: - Public properties
    
    var maxValue: Decimal?
    
    // MARK: -
    
    init(maxValue: Decimal?) {
        self.maxValue = maxValue
    }
    
    // MARK: - Overridden
    
    override func validate(value: Decimal?) -> Bool {
        guard let value = value, let maxValue = self.maxValue else {
            return true
        }
        
        return value <= maxValue
    }
}
