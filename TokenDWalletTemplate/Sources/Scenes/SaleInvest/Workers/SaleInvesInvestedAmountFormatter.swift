import Foundation

protocol SaleInvestInvestedAmountFormatterProtocol {
    func assetAmountToString(_ amount: Decimal) -> String
}

extension SaleInvest {
    typealias InvestedAmountFormatterProtocol = SaleInvestInvestedAmountFormatterProtocol
    
    class InvestAmountFormatter: SharedAmountFormatter { }
}

extension SaleInvest.InvestAmountFormatter: SaleInvest.InvestedAmountFormatterProtocol {
    
}
