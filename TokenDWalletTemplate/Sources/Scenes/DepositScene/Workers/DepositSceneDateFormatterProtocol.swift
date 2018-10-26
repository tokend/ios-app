import Foundation

protocol DepositSceneDateFormatterProtocol {
    func formatExpiratioDate(_ date: Date) -> String
}

extension DepositScene {
    typealias DateFormatterProtocol = DepositSceneDateFormatterProtocol
}
