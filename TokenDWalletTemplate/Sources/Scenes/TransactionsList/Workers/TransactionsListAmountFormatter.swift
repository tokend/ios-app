import Foundation

protocol TransactionsListSceneAmountFormatterProtocol {
    func formatAmount(
        _ amount: TransactionsListScene.Model.Amount
        ) -> String
}

extension TransactionsListScene {
    typealias AmountFormatterProtocol = TransactionsListSceneAmountFormatterProtocol
    
    class AmountFormatter: SharedAmountFormatter { }
}

extension TransactionsListScene.AmountFormatter: TransactionsListScene.AmountFormatterProtocol {
    func formatAmount(_ amount: TransactionsListScene.Model.Amount) -> String {
        return self.formatAmount(amount.value, currency: amount.asset)
    }
}
