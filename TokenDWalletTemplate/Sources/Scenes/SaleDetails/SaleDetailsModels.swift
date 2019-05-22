import Foundation

public enum SaleDetails {
    
    // MARK: - Typealiases
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension SaleDetails.Model {
    
    public class SceneModel {
        
        public var tabs: [TabModel]
        
        public init() {
            self.tabs = []
        }
    }
    
    public struct TabModel {
        
        public let contentModel: Any
    }
    
    public struct TabViewModel {
        
        public let contentViewModel: Any
    }
}

// MARK: - Events

extension SaleDetails.Event {
    
    public typealias Model = SaleDetails.Model
    
    public enum OnViewDidLoad {
        
        public struct Request {}
    }
    
    public enum OnTabsUpdated {
        
        public struct Response {
            
            public let contentModels: [Any]
        }
        
        public struct ViewModel {
            
            public let contentViewModels: [Any]
        }
    }
}
