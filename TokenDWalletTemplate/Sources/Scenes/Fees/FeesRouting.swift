import Foundation

extension Fees {
    struct Routing {
        let showProgress: () -> Void
        let hideProgress: () -> Void
        let showMessage: (_ message: String) -> Void
    }
}
