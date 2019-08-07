import Foundation

extension SaleDetails {
    struct Routing {
        let onShowProgress: () -> Void
        let onHideProgress: () -> Void
        let onShowError: (_ erroMessage: String) -> Void
        let onPresentPicker: (
        _ title: String,
        _ options: [String],
        _ onSelect: @escaping (_ index: Int) -> Void
        ) -> Void
        let onSaleInvestAction: (_ sendInvestModel: SaleDetails.Model.SaleInvestModel) -> Void
        let onSaleInfoAction: (_ saleInfoModel: SaleDetails.Model.SaleInfoModel) -> Void
    }
}
