import UIKit

extension TransactionDetails {
    class DateFormatter: DateFormatterProtocol {
        func dateToString(date: Date) -> String {
            let formatter = Foundation.DateFormatter()
            formatter.dateFormat = "dd MMM yyyy h:mm a"
            formatter.amSymbol = "AM"
            formatter.pmSymbol = "PM"
            let ledgerCloseTime = formatter.string(from: date)
            return ledgerCloseTime
        }
    }
}
