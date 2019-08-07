import Foundation

protocol TransactionDetailsAmountFormatterProtocol {
    func formatAmount(_ amount: TransactionDetails.Model.Amount) -> String
}

extension TransactionDetails {
    typealias AmountFormatterProtocol = TransactionDetailsAmountFormatterProtocol
}
