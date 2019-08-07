import Foundation

extension CreateOffer {
    struct Routing {
        let showProgress: () -> Void
        let hideProgress: () -> Void
        let onAction: (Model.CreateOfferModel) -> Void
        let onShowError: (_ error: String) -> Void
    }
}
