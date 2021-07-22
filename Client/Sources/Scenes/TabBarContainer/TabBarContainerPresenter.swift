import Foundation

public protocol TabBarContainerPresentationLogic {
    typealias Event = TabBarContainer.Event
}

extension TabBarContainer {
    public typealias PresentationLogic = TabBarContainerPresentationLogic
    
    @objc(TabBarContainerPresenter)
    public class Presenter: NSObject {
        
        public typealias Event = TabBarContainer.Event
        public typealias Model = TabBarContainer.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        
        // MARK: -
        
        public init(
            presenterDispatch: PresenterDispatch
        ) {
            
            self.presenterDispatch = presenterDispatch
        }
    }
}

extension TabBarContainer.Presenter: TabBarContainer.PresentationLogic { }
