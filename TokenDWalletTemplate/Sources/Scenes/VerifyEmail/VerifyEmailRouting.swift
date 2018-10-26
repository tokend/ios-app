import Foundation

extension VerifyEmail {
    struct Routing {
        let showProgress: () -> Void
        let hideProgress: () -> Void
        let showErrorMessage: (_ errorMessage: String) -> Void
        let onEmailVerified: () -> Void
    }
}
