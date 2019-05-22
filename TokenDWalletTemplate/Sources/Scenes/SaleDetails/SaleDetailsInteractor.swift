import Foundation
import RxCocoa
import RxSwift

public protocol SaleDetailsBusinessLogic {
    
    func onViewDidLoad(request: SaleDetails.Event.OnViewDidLoad.Request)
}

extension SaleDetails {
    
    public typealias BusinessLogic = SaleDetailsBusinessLogic
    
    public class Interactor {
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private let dataProvider: DataProvider
        
        private let sceneModel: Model.SceneModel
        
        private let disposeBag = DisposeBag()
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic,
            dataProvider: DataProvider
            ) {
            
            self.sceneModel = Model.SceneModel()
            self.presenter = presenter
            self.dataProvider = dataProvider
        }
        
        // MARK: - Private
        
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
            let contentModels: [Any] = self.sceneModel.tabs.map { (tab) -> Any in
                return tab.contentModel
            }
            let response = Event.OnTabsUpdated.Response(contentModels: contentModels)
            self.presenter.presentTabsUpdated(response: response)
        }
    }
}

extension SaleDetails.Interactor: SaleDetails.BusinessLogic {
    
    public func onViewDidLoad(request: SaleDetails.Event.OnViewDidLoad.Request) {
        self.observeData()
    }
}
