import Foundation

extension QRCodeScene {
    
    public struct Routing {
        
        public let onBackAction: () -> Void
        public let onShare: (String) -> Void
    }
}
