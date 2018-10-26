import Foundation

extension ExploreTokensScene {
    struct Routing {
        let onDidSelectToken: (_ tokenId: ExploreTokensScene.TokenIdentifier) -> Void
        let onDidSelectHistoryForBalance: (_ balanceId: String) -> Void
        let onError: (_ message: String) -> Void
    }
}
