import Foundation

extension BalancesList {
    public struct Routing {
        let onBalanceSelected: (_ balanceId: String) -> Void
        let showProgress: () -> Void
        let hideProgress: () -> Void
    }
}
