import Foundation
import RxSwift

public protocol BalanceHeaderBusinessLogic {
    typealias Event = BalanceHeader.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
}

extension BalanceHeader {
    public typealias BusinessLogic = BalanceHeaderBusinessLogic
    
    @objc(BalanceHeaderInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = BalanceHeader.Event
        public typealias Model = BalanceHeader.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private let balanceFetcher: BalanceFetcherProtocol
        private let disposeBag: DisposeBag = DisposeBag()
        
        private let rateAsset: String = "USD"
        
        private var sceneModel: Model.SceneModel
        
        // MARK: -
        
        init(
            sceneModel: Model.SceneModel,
            presenter: PresentationLogic,
            balanceFetcher: BalanceFetcherProtocol
            ) {
            
            self.sceneModel = sceneModel
            self.presenter = presenter
            self.balanceFetcher = balanceFetcher
        }
        
        // MARK: - Private
        
        private func observeBalances() {
            self.balanceFetcher
                .observeBalance()
                .subscribe(onNext: { [weak self] (balance) in
                    self?.sceneModel.balance = balance
                    self?.updateBalance()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func updateBalance() {
            guard let balance = self.sceneModel.balance else {
                return
            }
            
            let balanceAmount = Event.Model.Amount(
                value: balance.balance.value,
                asset: balance.balance.asset
            )
            
            let response = Event.BalanceUpdated.Response(
                balanceAmount: balanceAmount,
                rateAmount: balance.convertedBalance,
                iconUrl: balance.iconUrl
            )
            self.presenter.presentBalanceUpdated(response: response)
        }
    }
}

extension BalanceHeader.Interactor: BalanceHeader.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        self.observeBalances()
    }
}
