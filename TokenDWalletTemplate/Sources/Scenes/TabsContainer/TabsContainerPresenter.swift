import Foundation

public protocol TabsContainerPresentationLogic {
    
    typealias Event = TabsContainer.Event
    
    func presentTabsUpdated(response: Event.TabsUpdated.Response)
    func presentTabWasSelected(response: Event.TabWasSelected.Response)
}

extension TabsContainer {
    
    public typealias PresentationLogic = TabsContainerPresentationLogic
    
    @objc(TabsContainerPresenter)
    public class Presenter: NSObject {
        
        public typealias Event = TabsContainer.Event
        public typealias Model = TabsContainer.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        
        // MARK: -
        
        public init(presenterDispatch: PresenterDispatch) {
            self.presenterDispatch = presenterDispatch
        }
    }
}

extension TabsContainer.Presenter: TabsContainer.PresentationLogic {
    
    public func presentTabsUpdated(response: Event.TabsUpdated.Response) {
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayTabsUpdated(viewModel: viewModel)
        }
    }
    
    public func presentTabWasSelected(response: Event.TabWasSelected.Response) {
        
    }
}
