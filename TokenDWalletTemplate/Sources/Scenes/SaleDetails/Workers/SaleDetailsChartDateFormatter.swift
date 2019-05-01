import Foundation

protocol SaleDetailsChartDateFormatterProtocol {
    func dateToString(_ date: Date) -> String
    func formatDateForXAxis(_ date: Date, type: SaleDetails.Model.Period) -> String
}

extension SaleDetails {
    typealias ChartDateFormatterProtocol = SaleDetailsChartDateFormatterProtocol
}

extension SaleDetails {
    
    class ChartDateFormatter: ChartDateFormatterProtocol {
        
        // MARK: - Private properties
        
        private let dateFormatter: Foundation.DateFormatter
        private let axisDateFormatter: DateFormatter
        
        // MARK: -
        
        init() {
            self.dateFormatter = Foundation.DateFormatter()
            self.dateFormatter.dateFormat = "HH:mm, dd MMM yy"
            
            self.axisDateFormatter = DateFormatter()
        }
        
        // MARK: - ChartDateFormatterProtocol
        
        func dateToString(_ date: Date) -> String {
            return self.dateFormatter.string(from: date)
        }
        
        func formatDateForXAxis(
            _ date: Date,
            type: Model.Period
            ) -> String {
            
            switch type {
                
            case .hour:
                self.axisDateFormatter.dateFormat = "HH:mm"
                
            case .day:
                self.axisDateFormatter.dateFormat = "HH:mm"
                
            case .week:
                self.axisDateFormatter.dateFormat = "dd MMM"
                
            case .month:
                self.axisDateFormatter.dateFormat = "dd MMM"
                
            case .year:
                self.axisDateFormatter.dateFormat = "MMM yyyy"
            }
            
            return self.axisDateFormatter.string(from: date)
        }
    }
}
