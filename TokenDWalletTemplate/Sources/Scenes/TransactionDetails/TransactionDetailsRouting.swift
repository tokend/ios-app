import Foundation

extension TransactionDetails {
    struct Routing {
        let successAction: () -> Void
        let showProgress: () -> Void
        let hideProgress: () -> Void
        let showError: (String) -> Void
    }
}
