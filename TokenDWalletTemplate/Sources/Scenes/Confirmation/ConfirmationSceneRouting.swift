import Foundation

extension ConfirmationScene {
    struct Routing {
        let onShowProgress: () -> Void
        let onHideProgress: () -> Void
        let onShowError: (_ erroMessage: String) -> Void
        let onConfirmationSucceeded: () -> Void
    }
}
