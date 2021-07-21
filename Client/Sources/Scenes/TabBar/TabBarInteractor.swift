import Foundation
import RxSwift

public protocol TabBarBusinessLogic {
    typealias Event = TabBar.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request)
    func onDidSelectTabSync(request: Event.DidSelectTabSync.Request)
}

extension TabBar {
    public typealias BusinessLogic = TabBarBusinessLogic
    
    @objc(TabBarInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = TabBar.Event
        public typealias Model = TabBar.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private var sceneModel: Model.SceneModel
        private let tabProvider: TabProviderProtocol
        private let disposeBag: DisposeBag = .init()
        
        var selectedTab: Model.TabItem? {
            tab(with: sceneModel.selectedTabIdentifier)
        }
        
        // MARK: -
        
        init(
            presenter: PresentationLogic,
            selectedTabIdentifier: Model.TabIdentifier?,
            tabProvider: TabProviderProtocol
        ) {
            
            self.presenter = presenter
            self.tabProvider = tabProvider
            
            self.sceneModel = .init(
                tabs: tabProvider.tabs,
                selectedTabIdentifier: selectedTabIdentifier
            )
        }
    }
}

// MARK: - Private methods

private extension TabBar.Interactor {
    
    func observeTabs() {
        tabProvider
            .observeTabs()
            .subscribe(onNext: { [weak self] (tabs) in
                self?.sceneModel.tabs = tabs
                self?.checkSelectedTab()
                self?.presentSceneDidUpdate(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    func checkSelectedTab() {
        if selectedTab == nil {
            sceneModel.selectedTabIdentifier = sceneModel.tabs.first?.identifier
            // FIXME: - Handle what to do if no item
        }
    }
    
    func tab(with identifier: Model.TabIdentifier?) -> Model.TabItem? {
        sceneModel.tabs.first { $0.identifier == identifier }
    }
    
    func presentSceneDidUpdate(animated: Bool) {
        let response: Event.SceneDidUpdate.Response = .init(
            sceneModel: sceneModel,
            animated: animated
        )
        presenter.presentSceneDidUpdate(response: response)
    }
    
    func presentSceneDidUpdateSync(animated: Bool) {
        let response: Event.SceneDidUpdateSync.Response = .init(
            sceneModel: sceneModel,
            animated: animated
        )
        presenter.presentSceneDidUpdateSync(response: response)
    }
}

extension TabBar.Interactor: TabBar.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        
        observeTabs()
    }
    
    public func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request) {
        
        checkSelectedTab()
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidSelectTabSync(request: Event.DidSelectTabSync.Request) {
        
        guard let tab = self.tab(with: request.identifier)
        else {
            return
        }
        
        if request.shouldChangeSelectedTab {
            self.sceneModel.selectedTabIdentifier = tab.identifier
        }
        
        presentSceneDidUpdateSync(animated: true)
    }
}
