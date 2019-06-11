import Foundation
import RxCocoa
import RxSwift

public protocol TabsContainerBusinessLogic {
    
    typealias Event = TabsContainer.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onTabWasSelected(request: Event.TabWasSelected.Request)
    func onTabScrolled(request: Event.TabScrolled.Request)
}

extension TabsContainer {
    
    public typealias BusinessLogic = TabsContainerBusinessLogic
    
    @objc(TabsContainerInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = TabsContainer.Event
        public typealias Model = TabsContainer.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private let contentProvider: ContentProvider
        private let sceneModel: Model.SceneModel
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic,
            contentProvider: ContentProvider,
            sceneModel: Model.SceneModel
            ) {
            
            self.presenter = presenter
            self.contentProvider = contentProvider
            self.sceneModel = sceneModel
        }
        
        // MARK: - Private
        
        private func observerContent() {
            self.contentProvider.observeTabs()
                .subscribe(onNext: { [weak self] (tabs) in
                    self?.sceneModel.tabs = tabs
                    self?.onTabsUpdated()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func onTabsUpdated() {
            let previoslySelectedTabId: Model.TabIdentifier?
            if let selectedId = self.sceneModel.selectedTabId {
                previoslySelectedTabId = selectedId
            } else {
                previoslySelectedTabId = self.sceneModel.tabs.first?.identifier
            }
            
            let selectedTabIndex: Int?
            if let selectedId = previoslySelectedTabId {
                selectedTabIndex = self.sceneModel.tabs.firstIndex(where: { (tab) -> Bool in
                    return tab.identifier == selectedId
                })
            } else {
                selectedTabIndex = nil
            }
            
            let response = Event.TabsUpdated.Response(
                tabs: self.sceneModel.tabs,
                selectedTabIndex: selectedTabIndex
            )
            self.presenter.presentTabsUpdated(response: response)
        }
    }
}

extension TabsContainer.Interactor: TabsContainer.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        self.observerContent()
    }
    
    public func onTabWasSelected(request: Event.TabWasSelected.Request) {
        guard let selectedTabIndex = self.sceneModel.tabs.firstIndex(where: { (tab) -> Bool in
            return tab.identifier == request.identifier
        }) else {
            return
        }
        
        let tab = self.sceneModel.tabs[selectedTabIndex]
        self.sceneModel.selectedTabId = tab.identifier
        
        let response = Event.TabWasSelected.Response(selectedTabIndex: selectedTabIndex)
        self.presenter.presentTabWasSelected(response: response)
    }
    
    public func onTabScrolled(request: Event.TabScrolled.Request) {
        let tabIndex = max(0, min(self.sceneModel.tabs.count - 1, request.tabIndex))
        guard tabIndex < self.sceneModel.tabs.count else {
            return
        }
        
        let tabId = self.sceneModel.tabs[tabIndex].identifier
        guard self.sceneModel.selectedTabId != tabId else {
            return
        }
        
        self.sceneModel.selectedTabId = tabId
        
        let response = Event.SelectedTabChanged.Response(selectedTabIndex: tabIndex)
        self.presenter.presentSelectedTabChanged(response: response)
    }
}
