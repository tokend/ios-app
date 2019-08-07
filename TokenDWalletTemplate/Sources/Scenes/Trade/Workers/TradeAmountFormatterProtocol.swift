import UIKit

protocol TradeAmountFormatterProtocol {
    func formatToken(_ amount: Trade.Model.Amount) -> String
    func formatTradeOrderToken(value: Decimal) -> String
}

extension Trade {
    typealias AmountFormatterProtocol = TradeAmountFormatterProtocol
    
    class AmountFormatter: SharedAmountFormatter { }
}

extension Trade.AmountFormatter: Trade.AmountFormatterProtocol {
    func formatToken(_ amount: Trade.Model.Amount) -> String {
        return "\(amount.value) \(amount.currency)"
    }
    
    func formatTradeOrderToken(value: Decimal) -> String {
        return "\(value)"
    }
}
