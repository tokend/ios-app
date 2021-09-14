import Foundation

extension SendAmountScene {
    
    public struct Routing {
        
        public let onContinue: (
            _ amount: Decimal,
            _ assetCode: String,
            _ isPayingFeeForRecipient: Bool,
            _ description: String?
        ) -> Void
    }
}
