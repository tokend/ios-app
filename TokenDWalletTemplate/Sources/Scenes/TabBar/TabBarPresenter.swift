import Foundation

public protocol TabBarPresentationLogic {
    typealias Event = TabBar.Event
    
    func presenterViewDidLoad(response: Event.ViewDidLoad.Response)
    func presenterTabWasSelected(response: Event.TabWasSelected.Response)
    func presenterAction(response: Event.Action.Response)
}

extension TabBar {
    public typealias PresentationLogic = TabBarPresentationLogic
    
    @objc(TabBarPresenter)
    public class Presenter: NSObject {
        
        public typealias Event = TabBar.Event
        public typealias Model = TabBar.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        
        // MARK: -
        
        public init(presenterDispatch: PresenterDispatch) {
            self.presenterDispatch = presenterDispatch
        }
    }
}

extension TabBar.Presenter: TabBar.PresentationLogic {
    
    public func presenterViewDidLoad(response: Event.ViewDidLoad.Response) {
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayViewDidLoad(viewModel: viewModel)
        }
    }
    
    public func presenterTabWasSelected(response: Event.TabWasSelected.Response) {
        let viewModel = response
        self.presenterDispatch.display { (display) in
            display.displayTabWasSelected(viewModel: viewModel)
        }
    }
    
    public func presenterAction(response: Event.Action.Response) {
        let viewModel = response
        self.presenterDispatch.display { (display) in
            display.displayAction(viewModel: viewModel)
        }
    }
}
