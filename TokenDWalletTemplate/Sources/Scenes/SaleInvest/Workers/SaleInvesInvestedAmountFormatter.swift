import Foundation

protocol SaleInvestInvestedAmountFormatterProtocol {
    func formatAmount(_ amount: Decimal, currency: String) -> String
}

extension SaleInvest {
    typealias InvestedAmountFormatter = SalesInvestedAmountFormatterProtocol
    
    class InvestAmountFormatter: SharedAmountFormatter { }
}

extension SaleInvest.InvestAmountFormatter: SaleDetails.InvestedAmountFormatter {
    
}
