import UIKit

protocol ConfirmationPercentFormatterProtocol {
    func percentToString(value: Decimal) -> String
}

extension ConfirmationScene {
    typealias PercentFormatterProtocol = ConfirmationPercentFormatterProtocol
}
