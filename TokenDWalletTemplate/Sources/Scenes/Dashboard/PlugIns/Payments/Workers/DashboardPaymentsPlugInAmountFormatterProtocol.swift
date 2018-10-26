import Foundation

protocol DashboardPaymentsPlugInAmountFormatterProtocol {
    typealias Amount = DashboardPaymentsPlugIn.Model.Amount
    
    func formatBalance(_ balance: Amount) -> String
    func formatRate(_ rate: Amount) -> String
}

extension DashboardPaymentsPlugIn {
    typealias AmountFormatterProtocol = DashboardPaymentsPlugInAmountFormatterProtocol
}
