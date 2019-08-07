import Foundation

extension BalanceHeaderWithPicker {
    class AmountFormatter: SharedAmountFormatter { }
}

extension BalanceHeaderWithPicker.AmountFormatter: BalanceHeaderWithPicker.AmountFormatterProtocol {
    
    func formatBalance(_ balance: BalanceHeaderWithPickerAmountFormatterProtocol.Amount) -> String {
        return self.formatAmount(balance.value, currency: balance.asset)
    }
    
    func formatRate(_ rate: BalanceHeaderWithPickerAmountFormatterProtocol.Amount) -> String {
        return self.formatAmount(rate.value, currency: rate.asset)
    }
}
