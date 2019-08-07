import Foundation

extension ReceiveAddress {
    struct Routing {
        let onCopy: (_ stringToCopy: String) -> Void
        let onShare: (_ itemsToShare: [Any]) -> Void
    }
}
