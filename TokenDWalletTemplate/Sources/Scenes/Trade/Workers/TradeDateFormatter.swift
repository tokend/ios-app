import Foundation

extension Trade {
    class TradeDateFormatter: DateFormatterProtocol {
        func dateToString(_ date: Date) -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm dd MMM yy"
            return dateFormatter.string(from: date)
        }
        
        func formatDateForXAxis(
            _ date: Date,
            type: Trade.Model.Period
            ) -> String {
            
            let dateFormatter = DateFormatter()
            
            switch type {
            case .hour:
                dateFormatter.dateFormat = "HH:mm"
            case .day:
                dateFormatter.dateFormat = "HH:mm"
            case .week:
                dateFormatter.dateFormat = "dd MMM"
            case .month:
                dateFormatter.dateFormat = "dd MMM"
            case .year:
                dateFormatter.dateFormat = "MMM yyyy"
            }
            return dateFormatter.string(from: date)
        }
    }
}
