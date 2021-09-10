import Foundation

public protocol AmountFormatterProtocol {

    func format(
        _ amount: Decimal
    ) -> String
}
