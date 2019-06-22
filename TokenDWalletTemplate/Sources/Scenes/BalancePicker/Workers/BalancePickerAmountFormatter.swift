import Foundation

protocol BalancePickerAmountFormatterProtocol {
    func assetAmountToString(_ amount: Decimal) -> String
}

extension BalancePicker {
    typealias AmountFormatterProtocol = BalancePickerAmountFormatterProtocol
    
    class AmountFormatter: SharedAmountFormatter { }
}

extension BalancePicker.AmountFormatter: BalancePicker.AmountFormatterProtocol {
    
}
