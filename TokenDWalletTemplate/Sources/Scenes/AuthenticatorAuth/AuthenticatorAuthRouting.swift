import Foundation

extension AuthenticatorAuth {
    struct Routing {
        let openUrl: (_ url: URL) -> Void
        let showError: (_ message: String) -> Void
        let onSuccessfulSignIn: (_ account: String) -> Void
    }
}
