import Foundation
import RxSwift
import RxCocoa

protocol DashboardPaymentsPlugInBusinessLogic {
    typealias Event = DashboardPaymentsPlugIn.Event

    func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request)
    func onDidSelectBalance(request: Event.DidSelectBalance.Request)
    func onDidSelectViewMore(request: Event.DidSelectViewMore.Request)
}

extension DashboardPaymentsPlugIn {
    typealias BusinessLogic = DashboardPaymentsPlugInBusinessLogic
    
    class Interactor {
        
        typealias Event = DashboardPaymentsPlugIn.Event
        typealias Model = DashboardPaymentsPlugIn.Model
        
        // MARK: - Private properties
        
        private var sceneModel: Model.SceneModel
        
        private let balancesFetcher: BalancesFetcherProtocol
        private let rateProvider: RateProviderProtocol
        private let presenter: PresentationLogic
        
        private let rateAsset: String = "USD"
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        private var selectedBalanceRate: Model.Amount? {
            guard let selectedBalance = self.sceneModel.balances.first(where: { (balance) -> Bool in
                return balance.balanceId == self.sceneModel.selectedBalanceId
            }),
                let rate = self.rateProvider.rateForAmount(
                    selectedBalance.balance.value,
                    ofAsset: selectedBalance.balance.asset,
                    destinationAsset: self.rateAsset
                ) else {
                    return nil
            }
            return Model.Amount(value: rate, asset: self.rateAsset)
        }
        
        init(
            presenter: PresentationLogic,
            balancesFetcher: BalancesFetcherProtocol,
            rateProvider: RateProviderProtocol
            ) {
            
            self.sceneModel = Model.SceneModel(
                balances: [],
                selectedBalanceId: nil
            )
            self.presenter = presenter
            self.balancesFetcher = balancesFetcher
            self.rateProvider = rateProvider
        }
        
        private func observeBalancesFetcher() {
            self.balancesFetcher
                .observePaymentsPreviewBalances()
                .subscribe(onNext: { [weak self] (balances) in
                    self?.sceneModel.balances = balances
                    self?.onBalancesDidChange()
                    self?.updateSelectedBalance()
                    self?.onDidSelectBalance()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeRate() {
            self.rateProvider
                .rate
                .subscribe(onNext: { [weak self] (_) in
                    self?.onRateDidChange()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func onBalancesDidChange() {
            let response = Event.BalancesDidChange.Response(
                balances: self.sceneModel.balances
            )
            self.presenter.presentBalancesDidChange(response: response)
        }
        
        private func onRateDidChange() {
            let rate: Model.Amount? = self.selectedBalanceRate
            let response = Event.RateDidChange.Response(rate: rate)
            self.presenter.presentRateDidChange(response: response)
        }
        
        private func onDidSelectBalance() {
            guard let selectedBalance = self.selectedBalance() else {
                return
            }
            
            let rate: Model.Amount? = self.selectedBalanceRate
            let response = Event.BalanceDidChange.Response(
                balance: selectedBalance.balance,
                rate: rate
            )
            self.presenter.presentBalanceDidChange(response: response)
        }
        
        private func selectedBalanceId() -> String? {
            if let selectedId = self.sceneModel.selectedBalanceId {
                return selectedId
            }
            
            if let firstId = self.sceneModel.balances.first?.balanceId {
                self.sceneModel.selectedBalanceId = firstId
                self.updateSelectedBalance()
                return firstId
            }
            
            return nil
        }
        
        private func selectedBalance() -> Model.Balance? {
            guard let selectedId = self.selectedBalanceId() else {
                return nil
            }
            
            if let selectedBalance = self.sceneModel.balances.first(where: { (balance) -> Bool in
                return balance.balanceId == selectedId
            }) {
                return selectedBalance
            }
            
            if let first = self.sceneModel.balances.first {
                self.sceneModel.selectedBalanceId = first.balanceId
                self.updateSelectedBalance()
                return first
            }
            
            return nil
        }
        
        private func updateSelectedBalance() {
            let viewMoreAvailabilityChangedResponse = Event.ViewMoreAvailabilityChanged.Response(
                available: self.selectedBalance() != nil
            )
            self.presenter.presentViewMoreAvailabilityChanged(response: viewMoreAvailabilityChangedResponse)
            
            guard let selectedBalance = self.selectedBalance(),
                let index = self.sceneModel.balances.index(of: selectedBalance)
                else {
                    return
            }
            
            let response = Event.SelectedBalanceDidChange.Response(index: index)
            self.presenter.presentSelectedBalanceDidChange(respose: response)
            
            if let id = selectedBalance.balanceId {
                self.selectBalanceIfNeeded(id)
            }
        }
        
        private func selectBalanceIfNeeded(_ id: BalanceId) {
            guard self.sceneModel.selectedBalanceId != id else {
                return
            }
            self.sceneModel.selectedBalanceId = id
            self.onDidSelectBalance()
        }
    }
}

extension DashboardPaymentsPlugIn.Interactor: DashboardPaymentsPlugIn.BusinessLogic {
    
    func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request) {
        self.observeBalancesFetcher()
        self.observeRate()
    }
    
    func onDidSelectBalance(request: Event.DidSelectBalance.Request) {
        self.selectBalanceIfNeeded(request.id)
    }
    
    func onDidSelectViewMore(request: Event.DidSelectViewMore.Request) {
        guard let balanceId = self.selectedBalance()?.balanceId else {
            return
        }
        let response = Event.DidSelectViewMore.Response(
            balanceId: balanceId
        )
        self.presenter.presentDidSelectViewMore(response: response)
    }
}
