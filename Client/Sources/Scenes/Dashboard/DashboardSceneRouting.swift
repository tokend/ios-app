import Foundation

extension DashboardScene {
    
    public struct Routing {
        
        public let onAddAsset: () -> Void
        public let onBalanceTap: (_ id: String) -> Void
    }
}
