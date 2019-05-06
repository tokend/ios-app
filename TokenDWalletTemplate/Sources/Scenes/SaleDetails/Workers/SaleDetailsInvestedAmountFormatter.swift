import Foundation

protocol SaleDetailsInvestedAmountFormatterProtocol {
    
    func formatAmount(_ amount: Decimal, currency: String) -> String
}

extension SaleDetails {
    
    typealias InvestedAmountFormatter = SalesInvestedAmountFormatterProtocol
    
    class InvestAmountFormatter: SharedAmountFormatter { }
}

extension SaleDetails.InvestAmountFormatter: SaleDetails.InvestedAmountFormatter { }
