import UIKit

protocol ConfirmationAmountFormatterProtocol {
    func assetAmountToString(_ amount: Decimal) -> String
}

extension ConfirmationScene {
    typealias AmountFormatterProtocol = ConfirmationAmountFormatterProtocol
}
