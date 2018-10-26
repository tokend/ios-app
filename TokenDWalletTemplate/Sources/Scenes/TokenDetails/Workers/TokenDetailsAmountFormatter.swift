import Foundation

protocol TokenDetailsAmountFormatterProtocol {
    func assetAmountToString(_ amount: Decimal) -> String
}

extension TokenDetailsScene {
    typealias AmountFormatterProtocol = TokenDetailsAmountFormatterProtocol
}

extension TokenDetailsScene {
    class AmountFormatter: SharedAmountFormatter { }
}

extension TokenDetailsScene.AmountFormatter: TokenDetailsScene.AmountFormatterProtocol {
    
}
