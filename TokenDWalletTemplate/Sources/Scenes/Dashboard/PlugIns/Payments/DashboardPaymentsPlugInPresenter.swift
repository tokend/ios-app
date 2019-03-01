import Foundation

protocol DashboardPaymentsPlugInPresentationLogic {
    typealias Event = DashboardPaymentsPlugIn.Event

    func presentBalancesDidChange(response: Event.BalancesDidChange.Response)
    func presentSelectedBalanceDidChange(response: Event.SelectedBalanceDidChange.Response)
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
    
    func presentBalancesDidChange(response: Event.BalancesDidChange.Response) {
        let balances = response.balances.map { (balance) -> Event.Model.BalanceViewModel in
            return Event.Model.BalanceViewModel(
                id: balance.balanceId,
                name: balance.balance.asset,
                asset: balance.balance.asset
            )
        }
        let viewModel = Event.BalancesDidChange.ViewModel(
            balances: balances,
            selectedBalanceId: response.selectedBalanceId,
            selectedBalanceIndex: response.selectedBalanceIndex
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayBalancesDidChange(viewModel: viewModel)
        }
    }
    
    func presentSelectedBalanceDidChange(response: Event.SelectedBalanceDidChange.Response) {
        var rateRaw: String?
        if let rate = response.rate {
            rateRaw = self.amountFormatter.formatRate(rate)
        }
        let viewModel = Event.SelectedBalanceDidChange.ViewModel(
            balance: self.amountFormatter.formatBalance(response.balance),
            rate: rateRaw,
            id: response.id,
            asset: response.asset
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySelectedBalanceDidChange(viewModel: viewModel)
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
