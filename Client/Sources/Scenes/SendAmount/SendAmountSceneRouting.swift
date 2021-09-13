import Foundation

extension SendAmountScene {
    
    public struct Routing {
        
//        public let onBackAction: () -> Void
        public let onContinue: (
            _ amount: Decimal,
            _ assetCode: String,
            _ senderFee: Decimal,
            _ description: String?
        ) -> Void
    }
}
