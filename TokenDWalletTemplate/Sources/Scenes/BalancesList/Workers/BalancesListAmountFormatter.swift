import Foundation

protocol BalancesListAmountFormatterProtocol {
    func formatAmount(_ amount: Decimal, currency: String) -> String
}

extension BalancesList {
    typealias AmountFormatterProtocol = BalancesListAmountFormatterProtocol
    
    class AmountFormatter: SharedAmountFormatter { }
}

extension BalancesList.AmountFormatter: BalancesList.AmountFormatterProtocol {
    
}
