import Foundation

protocol FeeDataFormatterProtocol {
    func format(asset: String, value: Decimal) -> String
    func formatBounds(lower: Decimal, upper: Decimal, asset: String) -> String
    func formatPercent(value: Decimal) -> String
    func formatFeeType(feeType: Fees.Model.OperationType) -> String
    func formatSubtype(subtype: Fees.Model.Subtype) -> String
}

extension Fees {
    
    class FeeDataFormatter {
        
        // MARK: - Private properties
        
        private let amountFormatter: FeeAmountFormatterProtocol
        
        // (2^63 - 1) / 10^6
        private static let maxValue: Decimal = Decimal(string: "9223372036854.775807") ?? 0
        
        // MARK: -
        
        init(amountFormatter: FeeAmountFormatterProtocol) {
            self.amountFormatter = amountFormatter
        }
    }
}

extension Fees.FeeDataFormatter: FeeDataFormatterProtocol {
    
    func format(asset: String, value: Decimal) -> String {
        return value < Fees.FeeDataFormatter.maxValue
            ? "\(value) " + asset
            : "-/-"
    }
    
    func formatBounds(lower: Decimal, upper: Decimal, asset: String) -> String {
        if lower == 0 {
            if upper == Fees.FeeDataFormatter.maxValue {
                return Localized(.default_capitalized)
            } else {
                let upperBound = self.amountFormatter.assetAmountToString(
                    upper,
                    currency: asset
                )
                return Localized(
                    .up_to,
                    replace: [
                        .up_to_replace_amount: upperBound
                    ]
                )
            }
        } else {
            let lowerBound = self.amountFormatter.assetAmountToString(
                lower,
                currency: asset
            )
            if upper == Fees.FeeDataFormatter.maxValue {
                return Localized(
                    .from,
                    replace: [
                        .from_replace_amount: lowerBound
                    ]
                )
            } else {
                let upperBound = self.amountFormatter.assetAmountToString(
                    upper,
                    currency: asset
                )
                return Localized(
                    .from_to,
                    replace: [
                        .from_to_replace_lower: lowerBound,
                        .from_to_replace_upper: upperBound
                    ]
                )
            }
        }
    }
    
    func formatPercent(value: Decimal) -> String {
        return "\(value)%"
    }
    
    func formatFeeType(feeType: Fees.Model.OperationType) -> String {
        switch feeType {
            
        case .offerFee:
            return Localized(.order)
            
        case .paymentFee:
            return Localized(.payment)
            
        case .withdrawalFee:
            return Localized(.withdrawal)
            
        case .investFee:
            return Localized(.investment)
        }
    }
    
    func formatSubtype(subtype: Fees.Model.Subtype) -> String {
        switch subtype {
            
        case .incoming:
            return Localized(.incoming)
            
        case .incomingOutgoing:
            return Localized(.incoming_outgoing)
            
        case .outgoing:
            return Localized(.outgoing)
        }
    }
}
