import Foundation

protocol SaleDetailsAmountFormatterProtocol {
    func formatAmount(_ amount: Decimal, currency: String) -> String
}

extension SaleDetails {
    typealias AmountFormatterProtocol = SaleDetailsAmountFormatterProtocol
    
    class AmountFormatter: SharedAmountFormatter { }
}

extension SaleDetails.AmountFormatter: SaleDetails.AmountFormatterProtocol {
    
}
