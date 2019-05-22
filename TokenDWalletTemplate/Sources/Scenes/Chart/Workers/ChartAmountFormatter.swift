import Foundation

protocol ChartAmountFormatterProtocol {
    func formatAmount(_ amount: Decimal, currency: String) -> String
}

extension Chart {
    typealias AmountFormatterProtocol = ChartAmountFormatterProtocol
    
    class AmountFormatter: SharedAmountFormatter { }
}

extension Chart.AmountFormatter: Chart.AmountFormatterProtocol {
    
}
