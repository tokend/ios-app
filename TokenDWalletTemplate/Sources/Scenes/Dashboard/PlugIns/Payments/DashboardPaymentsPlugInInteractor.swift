import Foundation
import RxSwift
import RxCocoa

protocol DashboardPaymentsPlugInBusinessLogic {
    typealias Event = DashboardPaymentsPlugIn.Event

    func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request)
    func onSelectedBalanceDidChange(request: Event.SelectedBalanceDidChange.Request)
    func onDidSelectViewMore(request: Event.DidSelectViewMore.Request)
    func onDidInitiateRefresh(request: Event.DidInitiateRefresh.Request)
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
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeRate() {
            self.rateProvider
                .rate
                .subscribe(onNext: { [weak self] (_) in
                    self?.updateSelectedBalance()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func onBalancesDidChange() {
            self.setSelectedBalanceIdIfNeeded()
            self.updateSelectedBalance()
            
            let index = self.sceneModel.balances.firstIndex { (balance) -> Bool in
                return balance.balanceId == self.sceneModel.selectedBalanceId
            }
            
            var balances: [Model.Balance]
            
            if self.sceneModel.balances.isEmpty {
                let amount = Model.Amount(
                    value: 0,
                    asset: Localized(.no_balances)
                )
                let balance = Model.Balance(
                    balance: amount,
                    balanceId: nil
                )
                balances = [balance]
            } else {
                balances = self.sceneModel.balances
            }
            
            let response = Event.BalancesDidChange.Response(
                balances: balances,
                selectedBalanceId: self.sceneModel.selectedBalanceId,
                selectedBalanceIndex: index
            )
            self.presenter.presentBalancesDidChange(response: response)
        }
        
        private func updateSelectedBalance() {
            guard let selectedBalance = self.selectedBalance() else {
                return
            }
            
            let rateAmount = self.rateProvider.rateForAmount(
                selectedBalance.balance.value,
                ofAsset: selectedBalance.balance.asset,
                destinationAsset: self.rateAsset
            )
            
            var rate: Event.Model.Amount?
            
            if let amount = rateAmount {
                rate = Event.Model.Amount(
                    value: amount,
                    asset: rateAsset
                )
            }
            
            let response = Event.SelectedBalanceDidChange.Response(
                balance: selectedBalance.balance,
                rate: rate,
                id: selectedBalance.balanceId,
                asset: selectedBalance.balance.asset
            )
            self.presenter.presentSelectedBalanceDidChange(response: response)
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
        
        private func setSelectedBalanceIdIfNeeded() {
            if let selectedBalanceId = self.sceneModel.selectedBalanceId,
                self.sceneModel.balances.contains(where: { (balance) -> Bool in
                    return balance.balanceId == selectedBalanceId
                }) {
                return
            } else {
                self.setFirstBalanceSelected()
            }
        }
        
        private func setFirstBalanceSelected() {
            guard let balance = self.sceneModel.balances.first else {
                return
            }
            self.sceneModel.selectedBalanceId = balance.balanceId
        }
    }
}

extension DashboardPaymentsPlugIn.Interactor: DashboardPaymentsPlugIn.BusinessLogic {
    
    func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request) {
        self.observeBalancesFetcher()
        self.observeRate()
    }
    
    func onSelectedBalanceDidChange(request: Event.SelectedBalanceDidChange.Request) {
        self.sceneModel.selectedBalanceId = request.id
        self.updateSelectedBalance()
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
    
    func onDidInitiateRefresh(request: Event.DidInitiateRefresh.Request) {
        self.balancesFetcher.refreshPaymentsPreviewBalances()
    }
}
