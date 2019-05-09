import Foundation

public protocol SaleOverviewInvestedAmountFormatterProtocol {
    
    func formatAmount(_ amount: Decimal, currency: String) -> String
}

extension SaleOverview {
    
    public typealias InvestedAmountFormatter = SaleOverviewInvestedAmountFormatterProtocol
    
    public class InvestAmountFormatter: SharedAmountFormatter { }
}

extension SaleOverview.InvestAmountFormatter: SaleOverview.InvestedAmountFormatter { }
