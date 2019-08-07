import UIKit
import Charts

class ChartValueFormatter: NSObject {
    public var string: ((Double, AxisBase?) -> String?)?
}

extension ChartValueFormatter: IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return self.string?(value, axis) ?? ""
    }
}
