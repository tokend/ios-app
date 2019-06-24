import Foundation

extension Polls {
    
    public struct Routing {
        let onPresentPicker: (
        _ onSelect: @escaping (_ ownerAccountId: String, _ assetCode: String) -> Void
        ) -> Void
        let showError: (_ message: String) -> Void
        let showLoading: () -> Void
        let hideLoading: () -> Void
    }
}
