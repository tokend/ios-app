import Foundation

protocol SaleInvestAmountFormatterProtocol {
    func formatAmount(_ amount: Decimal, currency: String) -> String
}

extension SaleInvest {
    typealias AmountFormatterProtocol = SaleInvestAmountFormatterProtocol
    
    class AmountFormatter: SharedAmountFormatter { }
}

extension SaleInvest.AmountFormatter: SaleInvest.AmountFormatterProtocol {
    
}
