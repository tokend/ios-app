import Foundation

extension SendPaymentAmount {
    struct Routing {
        let onShowProgress: () -> Void
        let onHideProgress: () -> Void
        let onShowError: (_ erroMessage: String) -> Void
        let onPresentPicker: (
        _ title: String,
        _ options: [String],
        _ onSelect: @escaping (_ index: Int) -> Void
        ) -> Void
        let onSendAction: ((_ sendModel: Model.SendPaymentModel) -> Void)?
        let onShowWithdrawDestination: ((_ sendModel: Model.SendWithdrawModel) -> Void)?
        let showFeesOverview: (_ asset: String, _ feeType: Int32) -> Void
    }
}
