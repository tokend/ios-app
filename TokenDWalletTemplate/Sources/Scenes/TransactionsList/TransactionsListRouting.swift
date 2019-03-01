import Foundation

extension TransactionsListScene {
    struct Routing {
        let onDidSelectItemWithIdentifier: (Identifier, BalanceId) -> Void
        let showSendPayment: (_ balanceId: String?) -> Void
    }
}
