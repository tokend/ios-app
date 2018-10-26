import UIKit

protocol SaleDetailsDateFormatterProtocol {
    func dateToString(_ date: Date) -> String
}

extension SaleDetails {
    typealias DateFormatterProtocol = SaleDetailsDateFormatterProtocol
    
    class SaleDetailsDateFormatter: DateFormatterProtocol {
        func dateToString(_ date: Date) -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm dd MMM yy"
            return dateFormatter.string(from: date)
        }
    }
}
