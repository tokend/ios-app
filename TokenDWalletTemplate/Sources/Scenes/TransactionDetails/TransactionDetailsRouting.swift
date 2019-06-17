import Foundation

extension TransactionDetails {
    struct Routing {
        let successAction: () -> Void
        let showProgress: () -> Void
        let hideProgress: () -> Void
        let showError: (String) -> Void
        let showMessage: (String) -> Void
        let showDialog: (
        _ title: String,
        _ message: String,
        _ options: [String],
        _ onSelected: @escaping ((Int) -> Void)
        ) -> Void
    }
}
