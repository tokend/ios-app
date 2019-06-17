import Foundation

extension SaleInvest {
    public struct Routing {
        let onShowProgress: () -> Void
        let onHideProgress: () -> Void
        let onShowError: (_ erroMessage: String) -> Void
        let onShowMessage: (
        _ title: String,
        _ message: String
        ) -> Void
        let onPresentPicker: (
        _ options: [String],
        _ onSelect: @escaping (_ balanceId: String) -> Void
        ) -> Void
        let showDialog: (
        _ title: String,
        _ message: String,
        _ options: [String],
        _ onSelect: @escaping (_ index: Int) -> Void
        ) -> Void
        let onSaleInvestAction: (_ sendInvestModel: Model.SaleInvestModel) -> Void
        let onInvestHistory: (
        _ baseAsset: String,
        _ onCanceled: @escaping (() -> Void)
        ) -> Void
    }
}
