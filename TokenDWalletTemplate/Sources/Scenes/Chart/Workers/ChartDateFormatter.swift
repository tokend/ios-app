import UIKit

protocol ChartSceneDateFormatterProtocol {
    func dateToString(_ date: Date) -> String
}

extension Chart {
    typealias DateFormatterProtocol = ChartSceneDateFormatterProtocol
    
    class DateFormatter: DateFormatterProtocol {
        
        // MARK: - Private properties
        
        private let dateFormatter: Foundation.DateFormatter
        
        // MARK: -
        
        public init() {
            self.dateFormatter = Foundation.DateFormatter()
            self.dateFormatter.dateFormat = "HH:mm, dd MMM yy"
        }
        
        // MARK: - DateFormatterProtocol
        
        func dateToString(_ date: Date) -> String {
            return self.dateFormatter.string(from: date)
        }
    }
}
