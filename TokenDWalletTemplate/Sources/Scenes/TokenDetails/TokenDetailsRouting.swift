import Foundation

extension TokenDetailsScene {
    struct Routing {
        let onDidSelectHistoryForBalance: (_ balanceId: String) -> Void
        let onDidSelectDocument: (URL) -> Void
        let showSeparator: () -> Void
        let hideSeparator: () -> Void
    }
}
