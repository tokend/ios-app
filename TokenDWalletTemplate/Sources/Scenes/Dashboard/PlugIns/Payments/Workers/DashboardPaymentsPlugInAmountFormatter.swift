import Foundation

extension DashboardPaymentsPlugIn {
    class AmountFormatter: SharedAmountFormatter { }
}

extension DashboardPaymentsPlugIn.AmountFormatter: DashboardPaymentsPlugIn.AmountFormatterProtocol {
    
    func formatBalance(_ balance: Amount) -> String {
        return self.formatAmount(balance.value, currency: balance.asset)
    }
    
    func formatRate(_ rate: Amount) -> String {
        return self.formatAmount(rate.value, currency: rate.asset)
    }
}
