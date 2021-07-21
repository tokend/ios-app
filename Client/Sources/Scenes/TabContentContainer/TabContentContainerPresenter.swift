import Foundation

public protocol TabContentContainerPresentationLogic {
    
    typealias Event = TabContentContainer.Event
}

extension TabContentContainer {
    
    public typealias PresentationLogic = TabContentContainerPresentationLogic
    
    @objc(TabContentContainerPresenter)
    public class Presenter: NSObject {
        
        public typealias Event = TabContentContainer.Event
        public typealias Model = TabContentContainer.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        
        // MARK: -
        
        public init(presenterDispatch: PresenterDispatch) {
            self.presenterDispatch = presenterDispatch
        }
    }
}

extension TabContentContainer.Presenter: TabContentContainer.PresentationLogic { }
