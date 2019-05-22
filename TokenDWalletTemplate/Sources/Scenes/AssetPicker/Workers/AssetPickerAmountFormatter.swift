import Foundation

protocol AssetPickerAmountFormatterProtocol {
    func assetAmountToString(_ amount: Decimal) -> String
}

extension AssetPicker {
    typealias AmountFormatterProtocol = AssetPickerAmountFormatterProtocol
    
    class AmountFormatter: SharedAmountFormatter { }
}

extension AssetPicker.AmountFormatter: AssetPicker.AmountFormatterProtocol {
    
}
