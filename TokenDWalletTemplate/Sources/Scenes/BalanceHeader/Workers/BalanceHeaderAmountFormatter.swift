import Foundation

protocol BalanceHeaderAmountFormatterProtocol {
    typealias Amount = BalanceHeader.Model.Amount
    
    func formatBalance(_ balance: Amount) -> String
    func formatRate(_ rate: Amount) -> String
}

extension BalanceHeader {
    typealias AmountFormatterProtocol = BalanceHeaderAmountFormatterProtocol
}

extension BalanceHeader {
    class AmountFormatter: SharedAmountFormatter { }
}

extension BalanceHeader.AmountFormatter: BalanceHeader.AmountFormatterProtocol {
    
    func formatBalance(_ balance: BalanceHeader.Model.Amount) -> String {
        return self.formatAmount(balance.value, currency: balance.asset)
    }
    
    func formatRate(_ rate: BalanceHeader.Model.Amount) -> String {
        return self.formatAmount(rate.value, currency: rate.asset)
    }
}
