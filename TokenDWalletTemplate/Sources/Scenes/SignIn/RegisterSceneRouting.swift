import Foundation

extension RegisterScene {
    struct Routing {
        let showProgress: () -> Void
        let hideProgress: () -> Void
        let showErrorMessage: (_ errorMessage: String, _ completion: (() -> Void)?) -> Void
        let onSuccessfulLogin: (_ account: String) -> Void
        let onUnverifiedEmail: (_ walletId: String) -> Void
        let onPresentQRCodeReader: (_ completion: @escaping QRCodeReaderCompletion) -> Void
        let onShowRecoverySeed: (_ model: TokenDRegisterWorker.SignUpModel) -> Void
        let onRecovery: () -> Void
        let onAuthenticatorSignIn: () -> Void
        let showDialogAlert: (
        _ title: String,
        _ message: String,
        _ options: [String],
        _ onSelected: @escaping (_ selectedIndex: Int) -> Void,
        _ onCanceled: @escaping () -> Void
        ) -> Void
        let onSignedOut: () -> Void
        let onShowTerms: (_ url: URL) -> Void
    }
}
