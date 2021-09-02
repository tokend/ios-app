import Foundation

extension SendAmountScene {
    
    public struct Routing {
        
//        public let onBackAction: () -> Void
        public let onSelectBalance: (_ completion: @escaping (_ balanceId: String) -> Void) -> Void
        public let onContinue: () -> Void
    }
}
