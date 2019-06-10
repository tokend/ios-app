import Foundation

protocol SaleOverviewFundedValueFormatterProtocol {
    func formatFundedValue(value: String) -> NSAttributedString
}

extension SaleOverview {
    typealias FundedValueFormatterProtocol = SaleOverviewFundedValueFormatterProtocol
    
    class FundedValueFormatter: FundedValueFormatterProtocol {
        
        // MARK: - FundedValueFormatterProtocol
        
        func formatFundedValue(value: String) -> NSAttributedString {
            let fundedValue = NSMutableAttributedString(
                string: value + "\n",
                attributes: [
                    .font: Theme.Fonts.largePlainTextFont
                ]
            )
            let fundedText = NSMutableAttributedString(
                string: Localized(.funded_lowercase),
                attributes: [
                    .font: Theme.Fonts.plainTextFont
                ]
            )
            fundedValue.append(fundedText)
            return fundedValue
        }
    }
}
