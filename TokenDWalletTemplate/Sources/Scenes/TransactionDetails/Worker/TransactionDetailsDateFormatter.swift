import UIKit

extension TransactionDetails {
    
    public class DateFormatter: DateFormatterProtocol {
        
        // MARK: - Private properties
        
        private let dateFormatter: Foundation.DateFormatter
        
        // MARK: -
        
        public init() {
            self.dateFormatter = Foundation.DateFormatter()
            self.dateFormatter.dateFormat = "dd MMM yyyy h:mm a"
            self.dateFormatter.amSymbol = "AM"
            self.dateFormatter.pmSymbol = "PM"
        }
        
        // MARK: - DateFormatterProtocol
        
        func dateToString(date: Date) -> String {
            return self.dateFormatter.string(from: date)
        }
    }
}
