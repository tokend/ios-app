import Foundation
import AFDateHelper

extension TradeOffers {
    
    public class TradeDateFormatter: DateFormatterProtocol {
        
        // MARK: - Private properties
        
        private let dateFormatter: DateFormatter
        private let axisDateFormatter: DateFormatter
        
        // MARK: -
        
        public init() {
            self.dateFormatter = DateFormatter()
            self.axisDateFormatter = DateFormatter()
        }
        
        // MARK: - DateFormatterProtocol
        
        public func dateToString(_ date: Date, relative: Bool) -> String {
            if relative, date.compare(.isToday) {
                self.dateFormatter.dateFormat = "HH:mm"
            } else {
                self.dateFormatter.dateFormat = "HH:mm, dd MMM yy"
            }
            
            return self.dateFormatter.string(from: date)
        }
        
        public func formatDateForXAxis(
            _ date: Date,
            type: TradeOffers.Model.Period
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
