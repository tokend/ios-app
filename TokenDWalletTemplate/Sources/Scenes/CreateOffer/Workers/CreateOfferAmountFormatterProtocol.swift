import Foundation

protocol CreateOfferAmountFormatterProtocol {
    func formatTotal(_ amount: CreateOffer.Model.Amount) -> String
}

extension CreateOffer {
    typealias AmountFormatterProtocol = CreateOfferAmountFormatterProtocol
}
