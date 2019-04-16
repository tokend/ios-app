import Foundation

class DecimalFloorRoundingBehavior: NSDecimalNumberBehaviors {
    func roundingMode() -> NSDecimalNumber.RoundingMode {
        return .down
    }
    
    func scale() -> Int16 {
        return 0
    }
    
    func exceptionDuringOperation(
        _ operation: Selector,
        error: NSDecimalNumber.CalculationError,
        leftOperand: NSDecimalNumber,
        rightOperand: NSDecimalNumber?
        ) -> NSDecimalNumber? {
        
        return nil
    }
}
