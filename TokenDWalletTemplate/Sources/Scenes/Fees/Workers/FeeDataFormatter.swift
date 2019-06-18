import Foundation

protocol FeeDataFormatterProtocol {
    func format(asset: String, value: Decimal) -> String
    func formatPercent(value: Decimal) -> String
    func formatFeeType(feeType: Fees.Model.OperationType) -> String
    func formatSubtype(subtype: Fees.Model.Subtype) -> String
}

extension Fees {
    
    class FeeDataFormatter {
        
        // MARK: - Private properties
        
        // (2^63 - 1) / 10^6
        private static let maxValue: Decimal = Decimal(string: "9223372036854.775807") ?? 0
    }
}

extension Fees.FeeDataFormatter: FeeDataFormatterProtocol {
    
    func format(asset: String, value: Decimal) -> String {
        return value < Fees.FeeDataFormatter.maxValue
            ? "\(value) " + asset
            : "-/-"
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
