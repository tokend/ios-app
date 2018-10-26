import UIKit

protocol TradeDateFormatterProtocol {
    func dateToString(_ date: Date) -> String
    func formatDateForXAxis(_ date: Date, type: Trade.Model.Period) -> String
}

extension Trade {
    typealias DateFormatterProtocol = TradeDateFormatterProtocol
}
