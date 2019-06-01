import Foundation

extension Settings {
    struct Routing {
        let showProgress: () -> Void
        let hideProgress: () -> Void
        let showShadow: () -> Void
        let hideShadow: () -> Void
        let showErrorMessage: (_ errorMessage: String) -> Void
        let onCellSelected: (_ cellIdentifier: CellIdentifier) -> Void
        let onShowFees: () -> Void
        let onShowTerms: (_ url: URL) -> Void
        let onSignOut: () -> Void
    }
}
