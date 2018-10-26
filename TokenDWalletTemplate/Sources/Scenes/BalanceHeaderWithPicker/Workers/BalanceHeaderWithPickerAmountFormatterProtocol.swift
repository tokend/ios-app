import Foundation

protocol BalanceHeaderWithPickerAmountFormatterProtocol {
    typealias Amount = BalanceHeaderWithPicker.Model.Amount
    
    func formatBalance(_ balance: Amount) -> String
    func formatRate(_ rate: Amount) -> String
}

extension BalanceHeaderWithPicker {
    typealias AmountFormatterProtocol = BalanceHeaderWithPickerAmountFormatterProtocol
}
