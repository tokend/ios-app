import Foundation

protocol SalesInvestedAmountFormatterProtocol {
    func formatAmount(_ amount: Decimal, currency: String) -> String
}

extension Sales {
    typealias InvestedAmountFormatter = SalesInvestedAmountFormatterProtocol
    
    class AmountFormatter: SharedAmountFormatter { }
}

extension Sales.AmountFormatter: Sales.InvestedAmountFormatter {
    
}
