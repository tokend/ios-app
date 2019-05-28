import Foundation
import RxSwift

public protocol BalancesListBusinessLogic {
    typealias Event = BalancesList.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
}

extension BalancesList {
    public typealias BusinessLogic = BalancesListBusinessLogic
    
    @objc(BalancesListInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = BalancesList.Event
        public typealias Model = BalancesList.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private let dataProvider: DataProviderProtocol
        private let disposeBag: DisposeBag = DisposeBag()
        
        // MARK: -
        
        init(
            presenter: PresentationLogic,
            dataProvider: DataProviderProtocol
            ) {
            
            self.presenter = presenter
            self.dataProvider = dataProvider
        }
    }
}

extension BalancesList.Interactor: BalancesList.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        self.dataProvider
            .observeLoadingStatus()
            .subscribe(onNext: { [weak self] (status) in
                self?.presenter.presentLoadingStatusDidChange(response: status)
            })
            .disposed(by: self.disposeBag)
        
        self.dataProvider
            .observeData()
            .subscribe(onNext: { [weak self] (sections) in
                let response = Event.SectionsUpdated.Response(sections: sections)
                self?.presenter.presentSectionsUpdated(response: response)
            })
            .disposed(by: self.disposeBag)
    }
}
