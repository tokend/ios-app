import Foundation

public protocol TabBarContainerPresentationLogic {
    typealias Event = TabBarContainer.Event
    
    func presentViewDidLoad(response: Event.ViewDidLoad.Response)
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
        
        public init(presenterDispatch: PresenterDispatch) {
            self.presenterDispatch = presenterDispatch
        }
    }
}

extension TabBarContainer.Presenter: TabBarContainer.PresentationLogic {
    
    public func presentViewDidLoad(response: Event.ViewDidLoad.Response) {
        let viewModel = response
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayViewDidLoad(viewModel: viewModel)
        }
    }
}
