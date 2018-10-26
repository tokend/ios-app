import Foundation

protocol SendPaymentAmountFormatterProtocol {
    func assetAmountToString(_ amount: Decimal) -> String
}

extension SendPayment {
    typealias AmountFormatterProtocol = SendPaymentAmountFormatterProtocol
}

extension TokenDetailsScene.AmountFormatter: SendPayment.AmountFormatterProtocol {
    
}
