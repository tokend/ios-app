import Foundation

extension TransactionsListScene {
    struct Routing {
        let onDidSelectItemWithIdentifier: (Identifier, BalanceId) -> Void
        let showSendPayment: (_ balanceId: String?) -> Void
        let showWithdraw: (_ balanceId: String?) -> Void
        let showDeposit: (_ asset: String?) -> Void
        let showReceive: () -> Void
        let showShadow: () -> Void
        let hideShadow: () -> Void
    }
}
