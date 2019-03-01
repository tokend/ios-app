import Foundation

protocol TransactionsListSceneAmountFormatterProtocol {
    func formatAmount(
        _ amount: TransactionsListScene.Model.Amount,
        isIncome: Bool?
        ) -> String
}

extension TransactionsListScene {
    typealias AmountFormatterProtocol = TransactionsListSceneAmountFormatterProtocol
    
    class AmountFormatter: SharedAmountFormatter { }
}

extension TransactionsListScene.AmountFormatter: TransactionsListScene.AmountFormatterProtocol {
    func formatAmount(
        _ amount: TransactionsListScene.Model.Amount,
        isIncome: Bool?
        ) -> String {
        
        let value: Decimal
        if let isIncome = isIncome {
            let absValue = abs(amount.value)
            value = isIncome ? absValue : -absValue
        } else {
            value = amount.value
        }
        
        return self.formatAmount(value, currency: amount.asset)
    }
}
