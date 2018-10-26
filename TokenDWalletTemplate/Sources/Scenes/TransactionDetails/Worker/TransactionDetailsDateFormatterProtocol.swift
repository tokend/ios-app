import UIKit

protocol TransactionDetailsDateFormatterProtocol {
    func dateToString(date: Date) -> String
}

extension TransactionDetails {
    typealias DateFormatterProtocol = TransactionDetailsDateFormatterProtocol
}
