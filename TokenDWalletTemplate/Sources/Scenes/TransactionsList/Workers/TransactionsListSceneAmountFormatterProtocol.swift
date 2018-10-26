import Foundation

protocol TransactionsListSceneAmountFormatterProtocol {
    func formatAmount(
        _ amount: TransactionsListScene.Model.Amount
        ) -> String
}

extension TransactionsListScene {
    typealias AmountFormatterProtocol = TransactionsListSceneAmountFormatterProtocol
}
