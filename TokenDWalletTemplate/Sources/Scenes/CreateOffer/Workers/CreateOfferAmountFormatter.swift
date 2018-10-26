import Foundation

extension CreateOffer {
    class AmountFormatter: SharedAmountFormatter { }
}

extension CreateOffer.AmountFormatter: CreateOffer.AmountFormatterProtocol {
    func formatTotal(
        _ amount: CreateOffer.Model.Amount
        ) -> String {
        
        return self.formatAmount(amount.value ?? 0.0, currency: amount.asset)
    }
}
