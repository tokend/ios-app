import Foundation

extension UpdatePassword {
    struct Routing {
        let onShowProgress: () -> Void
        let onHideProgress: () -> Void
        let onShowErrorMessage: (String) -> Void
        let onSubmitSucceeded: () -> Void
    }
}
