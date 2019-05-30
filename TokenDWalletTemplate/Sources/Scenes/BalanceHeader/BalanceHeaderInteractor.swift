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
        private let rateProvider: RateProviderProtocol
        private let disposeBag: DisposeBag = DisposeBag()
        
        private let rateAsset: String = "USD"
        
        private var sceneModel: Model.SceneModel
        
        private var selectedBalanceRate: Model.Amount? {
            guard let selectedBalance = self.sceneModel.balance,
                let rate = self.rateProvider.rateForAmount(
                    selectedBalance.balance.value,
                    ofAsset: selectedBalance.balance.asset,
                    destinationAsset: self.rateAsset
                ) else {
                    return nil
            }
            return Model.Amount(value: rate, asset: self.rateAsset)
        }
        
        // MARK: -
        
        init(
            sceneModel: Model.SceneModel,
            presenter: PresentationLogic,
            balanceFetcher: BalanceFetcherProtocol,
            rateProvider: RateProviderProtocol
            ) {
            
            self.sceneModel = sceneModel
            self.presenter = presenter
            self.balanceFetcher = balanceFetcher
            self.rateProvider = rateProvider
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
        
        private func observeRate() {
            self.rateProvider
                .rate
                .subscribe(onNext: { [weak self] (_) in
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
            
            let rate = self.rateProvider.rateForAmount(
                balance.balance.value,
                ofAsset: balance.balance.asset,
                destinationAsset: self.rateAsset
            )
            
            var rateAmount: Event.Model.Amount?
            
            if let amount = rate {
                rateAmount = Event.Model.Amount(
                    value: amount,
                    asset: self.rateAsset
                )
            }
            let response = Event.BalanceUpdated.Response(
                balanceAmount: balanceAmount,
                rateAmount: rateAmount,
                iconUrl: balance.iconUrl
            )
            self.presenter.presentBalanceUpdated(response: response)
        }
    }
}

extension BalanceHeader.Interactor: BalanceHeader.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        self.observeBalances()
        self.observeRate()
    }
}
