import UIKit

public protocol TradesListAmountFormatterProtocol {
    
    func assetAmountToString(_ amount: Decimal) -> String
}

extension TradesList {
    public typealias AmountFormatterProtocol = TradesListAmountFormatterProtocol
    
    @objc(TradesListAmountFormatter)
    public class AmountFormatter: SharedAmountFormatter, AmountFormatterProtocol { }
}
