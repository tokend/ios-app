import Foundation

public protocol BalancesListPercentFormatterProtocol {
    func formatPercantage(percent: Double) -> String
}

extension BalancesList {
    typealias PercentFormatterProtocol = BalancesListPercentFormatterProtocol
    
    public class PercentFormatter: PercentFormatterProtocol {
        
        // MARK: - PercentFormatterProtocol
        
        public func formatPercantage(percent: Double) -> String {
            let value = ((percent * 100).rounded()) / 100
            return "\(value)%"
        }
    }
}
