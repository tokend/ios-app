import Foundation

extension DepositScene {
    
    class DateFormatter: DateFormatterProtocol {
        
        // MARK: - Private properties
        
        private let dateFormatter: Foundation.DateFormatter
        
        // MARK: -
        
        init() {
            self.dateFormatter = Foundation.DateFormatter()
            self.dateFormatter.dateStyle = .long
            self.dateFormatter.timeStyle = .short
        }
        
        // MARK: - Private properties
        
        func formatExpiratioDate(_ date: Date) -> String {
            return self.dateFormatter.string(from: date)
        }
    }
}
