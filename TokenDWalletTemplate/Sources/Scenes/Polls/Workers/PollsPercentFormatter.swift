import Foundation

public protocol PollsPercentFormatterProtocol {
    func formatPercantage(percent: Float) -> String
}

extension Polls {
    public typealias PercentFormatterProtocol = PollsPercentFormatterProtocol
    
    public class PercentFormatter: PercentFormatterProtocol {
        
        // MARK: - PercentFormatterProtocol
        
        public func formatPercantage(percent: Float) -> String {
            let value = ((percent * 100).rounded()) / 100
            return "\(value)%"
        }
    }
}
