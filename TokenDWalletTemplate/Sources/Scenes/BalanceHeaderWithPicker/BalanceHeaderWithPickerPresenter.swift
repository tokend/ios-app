import Foundation

protocol BalanceHeaderWithPickerPresentationLogic {
    typealias Event = BalanceHeaderWithPicker.Event

    func presentBalancesDidChange(response: Event.BalancesDidChange.Response)
    func presentSelectedBalanceDidChange(response: Event.SelectedBalanceDidChange.Response)
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
    func presentBalancesDidChange(response: Event.BalancesDidChange.Response) {
        let balances = response.balances.map { (balance) -> Model.BalanceViewModel in
            return Model.BalanceViewModel(
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
}
