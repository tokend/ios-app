import Foundation

extension DepositScene {
    class DateFormatter: DateFormatterProtocol {
        
        // MARK: - Private properties
        
        private lazy var expirationDateFormatter: Foundation.DateFormatter = {
            let formatter = Foundation.DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .short
            return formatter
        }()
        
        func formatExpiratioDate(_ date: Date) -> String {
            return self.expirationDateFormatter.string(from: date)
        }
    }
}
