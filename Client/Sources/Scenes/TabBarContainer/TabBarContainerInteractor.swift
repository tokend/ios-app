import Foundation

public protocol TabBarContainerBusinessLogic {
    typealias Event = TabBarContainer.Event
}

extension TabBarContainer {
    public typealias BusinessLogic = TabBarContainerBusinessLogic
    
    @objc(TabBarContainerInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = TabBarContainer.Event
        public typealias Model = TabBarContainer.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic
        ) {
            
            self.presenter = presenter
        }
    }
}

extension TabBarContainer.Interactor: TabBarContainer.BusinessLogic { }
