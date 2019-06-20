import Foundation

extension Polls {
    public struct Routing {
        let onPresentPicker: (
        _ options: [String],
        _ onSelect: @escaping (_ balanceId: String) -> Void
        ) -> Void
        
        let onPollSelected: () -> Void
    }
}
