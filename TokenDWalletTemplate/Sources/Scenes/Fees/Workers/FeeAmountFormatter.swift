import Foundation

protocol FeeAmountFormatterProtocol {
    func assetAmountToString(_ amount: Decimal, currency: String) -> String
}

extension Fees {
    typealias AmountFormatterProtocol = FeeAmountFormatterProtocol
    
    class AmountFormatter: SharedAmountFormatter { }
}

extension Fees.AmountFormatter: Fees.AmountFormatterProtocol {
    
}
