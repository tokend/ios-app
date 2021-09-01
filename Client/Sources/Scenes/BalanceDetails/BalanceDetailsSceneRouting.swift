import Foundation

extension BalanceDetailsScene {
    
    public struct Routing {
        
        public typealias OnDidSelectTransaction = (_ id: String) -> Void
        
        public let onDidSelectTransaction: OnDidSelectTransaction
        public let onReceive: () -> Void
        public let onSend: () -> Void
    }
}
