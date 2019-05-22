import Foundation

extension TabsContainer {
    
    public struct Routing {
        
        let onAction: () -> Void
        
        public init(onAction: @escaping () -> Void) {
            self.onAction = onAction
        }
    }
}
