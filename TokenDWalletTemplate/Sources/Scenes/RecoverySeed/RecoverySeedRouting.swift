import Foundation

extension RecoverySeed {
    struct Routing {
        let onShowMessage: (_ message: String) -> Void
        let onRegisterFailure: (_ message: String) -> Void
        let onShowAlertDialog: (
        _ message: String?,
        _ options: [String],
        _ onSelected: @escaping (_ selectedIndex: Int) -> Void
        ) -> Void
        let onSuccessfulRegister: (_ account: String, _ walletData: RegisterScene.Model.WalletData) -> Void
        let showLoading: () -> Void
        let hideLoading: () -> Void
    }
}
