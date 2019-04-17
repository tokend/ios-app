import UIKit

public protocol TradeOffersAmountFormatterProtocol {
    
    func formatToken(_ amount: TradeOffers.Model.Amount) -> String
    func formatTradeOrderToken(value: Decimal) -> String
    func assetAmountToString(_ amount: Decimal) -> String
}

extension TradeOffers {
    public typealias AmountFormatterProtocol = TradeOffersAmountFormatterProtocol
    
    public class AmountFormatter: SharedAmountFormatter { }
}

extension TradeOffers.AmountFormatter: TradeOffers.AmountFormatterProtocol {
    
    public func formatToken(_ amount: TradeOffers.Model.Amount) -> String {
        let value = amount.value
        let currency = amount.currency
        
        return "\(value) \(currency)"
    }
    
    public func formatTradeOrderToken(value: Decimal) -> String {
        return "\(value)"
    }
}
