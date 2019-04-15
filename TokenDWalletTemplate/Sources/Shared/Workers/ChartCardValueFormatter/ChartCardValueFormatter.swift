import UIKit
import Charts

public class ChartValueFormatter: NSObject {
    
    public var string: ((Double, AxisBase?) -> String?)?
}

extension ChartValueFormatter: IAxisValueFormatter {
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return self.string?(value, axis) ?? ""
    }
}
