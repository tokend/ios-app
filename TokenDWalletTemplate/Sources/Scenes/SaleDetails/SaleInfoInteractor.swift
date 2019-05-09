import Foundation
import RxCocoa
import RxSwift

protocol SaleInfoBusinessLogic {
    func onViewDidLoad(request: SaleInfo.Event.OnViewDidLoad.Request)
    func onTabDidChange(request: SaleInfo.Event.TabDidChange.Request)
}

extension SaleInfo {
    typealias BusinessLogic = SaleInfoBusinessLogic
    
    class Interactor {
        
        private let presenter: PresentationLogic
        private let dataProvider: DataProvider
        
        private let disposeBag = DisposeBag()
        
        private let sceneModel: Model.SceneModel
        
        init(
            sceneModel: Model.SceneModel,
            presenter: PresentationLogic,
            dataProvider: DataProvider
            ) {
            self.sceneModel = sceneModel
            self.presenter = presenter
            self.dataProvider = dataProvider
        }
        
        private func observeData() {
            self.dataProvider
                .observeData()
                .subscribe (onNext: { [weak self] (tabs) in
                    self?.sceneModel.tabs = tabs
                    self?.updateTabs()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func updateTabs() {
            let selectedTabId = self.sceneModel.selectedTabId
            
            guard let index = self.sceneModel.tabs.index(where: { (tab) -> Bool in
                return tab.title == selectedTabId
            }) else {
                if let tab = self.sceneModel.tabs.first {
                    self.setSelectedTab(id: tab.title)
                }
                return
            }
            
            let tab = self.sceneModel.tabs[index]
            let tabTitles = self.sceneModel.tabs.map { (tab) -> String in
                return tab.title
            }
            let response = Event.OnTabsUpdated.Response(
                tabTitles: tabTitles,
                selectedIndex: index,
                contentModel: tab.contentModel
            )
            self.presenter.presentTabsUpdated(response: response)
        }
        
        private func setSelectedTab(id: SaleInfo.Identifier) {
            self.sceneModel.selectedTabId = id
            self.updateTabs()
        }
        
        private func tabDidChange(id: String) {
            self.sceneModel.selectedTabId = id
            if let tab = self.sceneModel.tabs.first(where: { (tab) -> Bool in
                return tab.title == self.sceneModel.selectedTabId
            }) {
                let response = Event.TabDidChange.Response(tab: tab)
                self.presenter.presentTabDidChange(response: response)
            }
        }
    }
}

extension SaleInfo.Interactor: SaleInfo.BusinessLogic {
   
    func onViewDidLoad(request: SaleInfo.Event.OnViewDidLoad.Request) {
        self.observeData()
    }
    
    func onTabDidChange(request: SaleInfo.Event.TabDidChange.Request) {
        self.tabDidChange(id: request.id)
    }
}
