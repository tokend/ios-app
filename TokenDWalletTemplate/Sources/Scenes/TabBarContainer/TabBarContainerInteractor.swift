import Foundation

public protocol TabBarContainerBusinessLogic {
    typealias Event = TabBarContainer.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
}

extension TabBarContainer {
    public typealias BusinessLogic = TabBarContainerBusinessLogic
    
    @objc(TabBarContainerInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = TabBarContainer.Event
        public typealias Model = TabBarContainer.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private let contentProvider: ContentProviderProtocol
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic,
            contentProvider: ContentProviderProtocol
            ) {
            
            self.presenter = presenter
            self.contentProvider = contentProvider
        }
    }
}

extension TabBarContainer.Interactor: TabBarContainer.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        let sceneContent = self.contentProvider.getSceneContent()
        let response = Event.ViewDidLoad.Response(sceneContent: sceneContent)
        self.presenter.presentViewDidLoad(response: response)
    }
}
