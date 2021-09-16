import Foundation

extension SendAmountScene {
    
    public struct Routing {
        
        public let onContinue: (
            _ assetCode: String,
            _ isPayingFeeForRecipient: Bool,
            _ description: String?
        ) -> Void
    }
}
