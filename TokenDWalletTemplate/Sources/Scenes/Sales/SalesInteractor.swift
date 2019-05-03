import Foundation
import RxSwift
import RxCocoa

protocol SalesBusinessLogic {
    func onViewDidLoad(request: Sales.Event.ViewDidLoad.Request)
    func onDidInitiateRefresh(request: Sales.Event.DidInitiateRefresh.Request)
    func onDidInitiateLoadMore(request: Sales.Event.DidInitiateLoadMore.Request)
}

extension Sales {
    typealias BusinessLogic = SalesBusinessLogic
    
    class Interactor {
        
        private let presenter: PresentationLogic
        private let sectionsProvider: SectionsProvider
        
        private let disposeBag = DisposeBag()
        
        init(
            presenter: PresentationLogic,
            sectionsProvider: SectionsProvider
            ) {
            
            self.presenter = presenter
            self.sectionsProvider = sectionsProvider
        }
        
        private func getSalesCount(sections: [Sales.Model.SectionModel]) -> Int {
            return sections.reduce(0, { (x, y) -> Int in
                x + y.sales.count
            })
        }
        
        private func showEmptyView(message: String) {
            let response = Sales.Event.EmptyResult.Response(message: message)
            self.presenter.presentEmptyResult(response: response)
        }
    }
}

extension Sales.Interactor: Sales.BusinessLogic {
    
    func onViewDidLoad(request: Sales.Event.ViewDidLoad.Request) {
        self.sectionsProvider
            .observeLoadingStatus()
            .subscribe(onNext: { [weak self] (status) in
                self?.presenter.presentLoadingStatusDidChange(response: status)
            })
            .disposed(by: self.disposeBag)
        
        self.sectionsProvider
            .observeLoadingMoreStatus()
            .subscribe(onNext: { [weak self] (status) in
                self?.presenter.presentLoadingStatusDidChange(response: status)
            })
            .disposed(by: self.disposeBag)
        
        self.sectionsProvider
            .observeSections()
            .subscribe(onNext: { [weak self] (sections) in
                if self?.getSalesCount(sections: sections) == 0 {
                    self?.showEmptyView(message: Localized(.no_open_sales))
                } else {
                    let response = Sales.Event.SectionsUpdated.Response(sections: sections)
                    self?.presenter.presentSectionsUpdated(response: response)
                }
            })
            .disposed(by: self.disposeBag)
        
        self.sectionsProvider
            .observeErrorStatus()
            .subscribe(onNext: { [weak self] (error) in
                self?.showEmptyView(message: error.localizedDescription)
            })
            .disposed(by: self.disposeBag)
    }
    
    func onDidInitiateRefresh(request: Sales.Event.DidInitiateRefresh.Request) {
        self.sectionsProvider.refreshSales()
    }
    
    func onDidInitiateLoadMore(request: Sales.Event.DidInitiateLoadMore.Request) {
        self.sectionsProvider.loadMoreSales()
    }
}
