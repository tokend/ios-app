import Foundation

extension DepositScene {
    struct Routing {
        let onShare: (_ items: [Any]) -> Void
        let onError: (_ message: String) -> Void
    }
}
