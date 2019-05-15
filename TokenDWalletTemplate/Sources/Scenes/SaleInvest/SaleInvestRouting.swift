import Foundation

extension SaleInvest {
    public struct Routing {
        let onShowProgress: () -> Void
        let onHideProgress: () -> Void
        let onShowError: (_ erroMessage: String) -> Void
        let onPresentPicker: (
        _ title: String,
        _ options: [String],
        _ onSelect: @escaping (_ index: Int) -> Void
        ) -> Void
        let showDialog: (
        _ title: String,
        _ message: String,
        _ options: [String],
        _ onSelect: @escaping (_ index: Int) -> Void
        ) -> Void
        let onSaleInvestAction: (_ sendInvestModel: Model.SaleInvestModel) -> Void
    }
}
