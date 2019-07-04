import Foundation
import RxSwift

public protocol BalancePickerBusinessLogic {
    typealias Event = BalancePicker.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onDidFilter(request: Event.DidFilter.Request)
}

extension BalancePicker {
    public typealias BusinessLogic = BalancePickerBusinessLogic
    
    @objc(BalancePickerInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = BalancePicker.Event
        public typealias Model = BalancePicker.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private let balancesFetcher: BalancesFetcherProtocol
        private var sceneModel: Model.SceneModel
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        // MARK: -
        
        init(
            presenter: PresentationLogic,
            balancesFetcher: BalancesFetcherProtocol,
            sceneModel: Model.SceneModel
            ) {
            
            self.presenter = presenter
            self.balancesFetcher = balancesFetcher
            self.sceneModel = sceneModel
        }
        
        // MARK: - Private
        
        private func observeBalances() {
            self.balancesFetcher
                .observeBalances()
                .subscribe(onNext: { (balances) in
                    self.sceneModel.balances = balances
                    self.updateBalances()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func updateBalances() {
            let response: Event.BalancesUpdated.Response
            var balances = self.sceneModel.balances
            if let filter = self.sceneModel.filter,
                !filter.isEmpty {
                
                balances = balances.filter({ (balance) -> Bool in
                    return balance.assetCode.localizedCaseInsensitiveContains(filter)
                })
            }
            if balances.isEmpty {
                response = .empty
            } else {
                response = .balances(balances)
            }
            self.presenter.presentBalancesUpdated(response: response)
        }
    }
}

extension BalancePicker.Interactor: BalancePicker.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        self.observeBalances()
    }
    
    public func onDidFilter(request: Event.DidFilter.Request) {
        self.sceneModel.filter = request.filter
        self.updateBalances()
    }
}
