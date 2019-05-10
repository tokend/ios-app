import Foundation

public protocol TabsContainerPresentationLogic {
    
    typealias Event = TabsContainer.Event
    
    func presentTabsUpdated(response: Event.TabsUpdated.Response)
    func presentTabWasSelected(response: Event.TabWasSelected.Response)
    func presentSelectedTabChanged(response: Event.SelectedTabChanged.Response)
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
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayTabWasSelected(viewModel: viewModel)
        }
    }
    
    public func presentSelectedTabChanged(response: Event.SelectedTabChanged.Response) {
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySelectedTabChanged(viewModel: viewModel)
        }
    }
}
