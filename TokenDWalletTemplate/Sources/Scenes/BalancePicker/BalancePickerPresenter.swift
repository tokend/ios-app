import Foundation

public protocol BalancePickerPresentationLogic {
    typealias Event = BalancePicker.Event
    
    func presentBalancesUpdated(response: Event.BalancesUpdated.Response)
}

extension BalancePicker {
    public typealias PresentationLogic = BalancePickerPresentationLogic
    
    @objc(BalancePickerPresenter)
    public class Presenter: NSObject {
        
        public typealias Event = BalancePicker.Event
        public typealias Model = BalancePicker.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        private let amountFormatter: AmountFormatterProtocol
        
        // MARK: -
        
        init(
            presenterDispatch: PresenterDispatch,
            amountFormatter: AmountFormatterProtocol
            ) {
            
            self.presenterDispatch = presenterDispatch
            self.amountFormatter = amountFormatter
        }
    }
}

extension BalancePicker.Presenter: BalancePicker.PresentationLogic {
    
    public func presentBalancesUpdated(response: Event.BalancesUpdated.Response) {
        let viewModel: Event.BalancesUpdated.ViewModel
        switch response {
            
        case .balances(let models):
            let balances = models.map { (balance) -> BalancePicker.BalanceCell.ViewModel in
                let firstLetter = balance.assetCode.first?.description ?? ""
                let availableBalanceAmount = self.amountFormatter.assetAmountToString(balance.details.amount)
                let availableBalance = Localized(
                    .available_amount,
                    replace: [
                        .available_amount_replace_amount: availableBalanceAmount
                    ]
                )
                var imageRepresentation = Model.ImageRepresentation.abbreviation
                if let url = balance.iconUrl {
                    imageRepresentation = .image(url)
                }
                return BalancePicker.BalanceCell.ViewModel(
                    code: balance.assetCode,
                    imageRepresentation: imageRepresentation,
                    balance: availableBalance,
                    abbreviationBackgroundColor: TokenColoringProvider.shared.coloringForCode(balance.assetCode),
                    abbreviationText: firstLetter,
                    balanceId: balance.details.balanceId
                )
            }
            viewModel = .balances(balances)
            
        case .empty:
            viewModel = .empty
        }
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayBalancesUpdated(viewModel: viewModel)
        }
    }
}
