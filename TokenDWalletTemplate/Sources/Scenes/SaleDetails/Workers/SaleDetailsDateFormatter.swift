import UIKit

protocol SaleDetailsDateFormatterProtocol {
    func dateToString(_ date: Date) -> String
}

extension SaleDetails {
    typealias DateFormatterProtocol = SaleDetailsDateFormatterProtocol
    
    class SaleDetailsDateFormatter: DateFormatterProtocol {
        
        // MARK: - Private properties
        
        private let dateFormatter: DateFormatter
        
        // MARK: -
        
        public init() {
            self.dateFormatter = DateFormatter()
            self.dateFormatter.dateFormat = "HH:mm, dd MMM yy"
        }
        
        // MARK: - DateFormatterProtocol
        
        func dateToString(_ date: Date) -> String {
            return self.dateFormatter.string(from: date)
        }
    }
}
