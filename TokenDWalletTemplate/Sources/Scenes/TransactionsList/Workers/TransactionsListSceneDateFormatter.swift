import Foundation

extension TransactionsListScene {
    class DateFormatter: DateFormatterProtocol {
        
        private lazy var titleDateFormatter: Foundation.DateFormatter = {
            let formatter = Foundation.DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter
        }()
        private lazy var transactionDateFormatter: Foundation.DateFormatter = {
            let formatter = Foundation.DateFormatter()
            formatter.dateFormat = "dd MMM"
            return formatter
        }()
        
        func formatDateForTitle(_ date: Date) -> String {
            return self.titleDateFormatter.string(from: date)
        }
        
        func formatDateForTransaction(_ date: Date) -> String {
            return self.transactionDateFormatter.string(from: date)
        }
    }
}
