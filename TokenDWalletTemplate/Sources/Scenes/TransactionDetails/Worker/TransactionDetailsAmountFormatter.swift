import Foundation

extension TransactionDetails {
    class AmountFormatter: SharedAmountFormatter { }
}

extension TransactionDetails.AmountFormatter: TransactionDetails.AmountFormatterProtocol {
    func formatAmount(
        _ amount: TransactionDetails.Model.Amount
        ) -> String {
        
        return self.formatAmount(amount.value, currency: amount.asset)
    }
}
