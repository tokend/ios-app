import Foundation

protocol TransactionsListSceneDateFormatterProtocol {
    func formatDateForTitle(_ date: Date) -> String
    func formatDateForTransaction(_ date: Date) -> String
}

extension TransactionsListScene {
    typealias DateFormatterProtocol = TransactionsListSceneDateFormatterProtocol
}
