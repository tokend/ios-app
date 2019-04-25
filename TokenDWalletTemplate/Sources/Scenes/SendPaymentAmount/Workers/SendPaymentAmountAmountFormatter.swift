import Foundation

protocol SendPaymentAmountFormatterProtocol {
    func formatAmount(
        _ amount: Decimal,
        currency: String
        ) -> String
    
    func assetAmountToString(_ amount: Decimal) -> String
}

extension SendPaymentAmount {
    typealias AmountFormatterProtocol = SendPaymentAmountFormatterProtocol
    
    class AmountFormatter: SharedAmountFormatter { }
}

extension SendPaymentAmount.AmountFormatter: SendPaymentAmount.AmountFormatterProtocol {
    
}
