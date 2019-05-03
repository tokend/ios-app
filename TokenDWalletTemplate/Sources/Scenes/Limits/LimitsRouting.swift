import Foundation

extension Limits {
    
    public struct Routing {
        
        public let onShowError: (_ erroMessage: String) -> Void
        public let onShowProgress: () -> Void
        public let onHideProgress: () -> Void
        
        public init(
            onShowError: @escaping (_ erroMessage: String) -> Void,
            onShowProgress: @escaping () -> Void,
            onHideProgress: @escaping () -> Void
            ) {
            
            self.onShowError = onShowError
            self.onShowProgress = onShowProgress
            self.onHideProgress = onHideProgress
        }
    }
}
