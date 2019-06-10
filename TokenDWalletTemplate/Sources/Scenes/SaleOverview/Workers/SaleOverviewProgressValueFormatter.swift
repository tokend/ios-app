import Foundation
import UICircularProgressRing

extension SaleOverview {
    
    class CircleProgressValueFormatter: UICircularRingValueFormatter {
        func string(for value: Any) -> String? {
            if let float = value as? CGFloat {
                return "\(Int(float))%"
            }
            return nil
        }
    }
}
