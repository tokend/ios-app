import Foundation

extension SendAssetScene {
    
    public struct Routing {
        
        public let onScanRecipient: () -> Void
        public let onContinue: (_ recipient: String) -> Void
    }
}
