import Foundation

extension RecoverySeed {
    struct Routing {
        let onShowMessage: (_ message: String) -> Void
        let onShowAlertDialog: (
        _ message: String?,
        _ options: [String],
        _ onSelected: @escaping (_ selectedIndex: Int) -> Void
        ) -> Void
        let onProceed: () -> Void
    }
}
