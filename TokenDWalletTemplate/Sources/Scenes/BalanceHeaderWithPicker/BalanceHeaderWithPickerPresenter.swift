import Foundation

protocol BalanceHeaderWithPickerPresentationLogic {
    typealias Event = BalanceHeaderWithPicker.Event
    
    func presentBalanceDidChange(response: Event.BalanceDidChange.Response)
    func presentBalancesDidChange(response: Event.BalancesDidChange.Response)
    func presentRateDidChange(response: Event.RateDidChange.Response)
    func presentSelectedBalanceDidChange(respose: Event.SelectedBalanceDidChange.Response)
}

extension BalanceHeaderWithPicker {
    typealias PresentationLogic = BalanceHeaderWithPickerPresentationLogic
    
    class Presenter {
        
        typealias Event = BalanceHeaderWithPicker.Event
        typealias Model = BalanceHeaderWithPicker.Model
        
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

extension BalanceHeaderWithPicker.Presenter: BalanceHeaderWithPicker.PresentationLogic {
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
}
