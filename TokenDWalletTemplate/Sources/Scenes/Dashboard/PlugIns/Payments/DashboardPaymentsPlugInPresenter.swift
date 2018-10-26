import Foundation

protocol DashboardPaymentsPlugInPresentationLogic {
    typealias Event = DashboardPaymentsPlugIn.Event
    
    func presentBalanceDidChange(response: Event.BalanceDidChange.Response)
    func presentBalancesDidChange(response: Event.BalancesDidChange.Response)
    func presentRateDidChange(response: Event.RateDidChange.Response)
    func presentSelectedBalanceDidChange(respose: Event.SelectedBalanceDidChange.Response)
    func presentDidSelectViewMore(response: Event.DidSelectViewMore.Response)
    func presentViewMoreAvailabilityChanged(response: Event.ViewMoreAvailabilityChanged.Response)
}

extension DashboardPaymentsPlugIn {
    typealias PresentationLogic = DashboardPaymentsPlugInPresentationLogic
    
    class Presenter {
        
        typealias Event = DashboardPaymentsPlugIn.Event
        typealias Model = DashboardPaymentsPlugIn.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        private let amountFormatter: AmountFormatterProtocol
        
        init(
            presenterDispatch: PresenterDispatch,
            amountFormatter: AmountFormatterProtocol
            ) {
            
            self.presenterDispatch = presenterDispatch
            self.amountFormatter = amountFormatter
        }
        
        private func getRateStringFromRate(_ rate: Model.Amount?) -> String? {
            if let rate = rate {
                return self.amountFormatter.formatRate(rate)
            }
            return nil
        }
    }
}

extension DashboardPaymentsPlugIn.Presenter: DashboardPaymentsPlugIn.PresentationLogic {
    func presentBalanceDidChange(response: Event.BalanceDidChange.Response) {
        let viewModel = Event.BalanceDidChange.ViewModel(
            balance: self.amountFormatter.formatBalance(response.balance),
            rate: self.getRateStringFromRate(response.rate)
        )
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayBalanceDidChange(viewModel: viewModel)
        }
    }
    
    func presentBalancesDidChange(response: Event.BalancesDidChange.Response) {
        let balances = response.balances.map { (balance) -> Event.BalancesDidChange.ViewModel.Balance in
            return Event.BalancesDidChange.ViewModel.Balance(
                id: balance.balanceId,
                name: balance.balance.asset,
                asset: balance.balance.asset
            )
        }
        let viewModel = Event.BalancesDidChange.ViewModel(
            balances: balances
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayBalancesDidChange(viewModel: viewModel)
        }
    }
    
    func presentRateDidChange(response: Event.RateDidChange.Response) {
        let rate: String? = self.getRateStringFromRate(response.rate)
        let viewModel = Event.RateDidChange.ViewModel(rate: rate)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayRateDidChange(viewModel: viewModel)
        }
    }
    
    func presentSelectedBalanceDidChange(respose: Event.SelectedBalanceDidChange.Response) {
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySelectedBalanceDidChange(viewModel: respose)
        }
    }
    
    func presentDidSelectViewMore(response: Event.DidSelectViewMore.Response) {
        let viewModel = Event.DidSelectViewMore.ViewModel(
            balanceId: response.balanceId
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayDidSelectViewMore(viewModel: viewModel)
        }
    }
    
    func presentViewMoreAvailabilityChanged(response: Event.ViewMoreAvailabilityChanged.Response) {
        let viewModel = Event.ViewMoreAvailabilityChanged.ViewModel(
            enabled: response.available
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayViewMoreAvailabilityChanged(viewModel: viewModel)
        }
    }
}
