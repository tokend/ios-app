import Foundation

extension Polls {
    public struct Routing {
        let onPresentPicker: (
        _ onSelect: @escaping (_ ownerAccountId: String) -> Void
        ) -> Void
    }
}
