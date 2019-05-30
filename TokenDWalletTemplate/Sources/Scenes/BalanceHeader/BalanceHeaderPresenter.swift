import Foundation

public protocol BalanceHeaderPresentationLogic {
    typealias Event = BalanceHeader.Event
    
    func presentBalanceUpdated(response: Event.BalanceUpdated.Response)
}

extension BalanceHeader {
    public typealias PresentationLogic = BalanceHeaderPresentationLogic
    
    @objc(BalanceHeaderPresenter)
    public class Presenter: NSObject {
        
        public typealias Event = BalanceHeader.Event
        public typealias Model = BalanceHeader.Model
        
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
        
        private func getRateStringFromRate(_ rate: Model.Amount?) -> String? {
            if let rate = rate {
                return self.amountFormatter.formatRate(rate)
            }
            return nil
        }
    }
}

extension BalanceHeader.Presenter: BalanceHeader.PresentationLogic {
    
    public func presentBalanceUpdated(response: Event.BalanceUpdated.Response) {
        let balance = self.amountFormatter.formatBalance(response.balanceAmount)
        let rate = self.getRateStringFromRate(response.rateAmount)
        var imageRepresentation: Model.ImageRepresentation
        
        if let url = response.iconUrl {
            imageRepresentation = .image(url)
        } else {
            let abbreviationColor = TokenColoringProvider
                .shared
                .coloringForCode(response.balanceAmount.asset)
            
            let abbreviationCode = response.balanceAmount.asset.first?.description ?? ""
            imageRepresentation = .abbreviation(
                text: abbreviationCode,
                color: abbreviationColor
            )
        }
        let viewModel = Event.BalanceUpdated.ViewModel(
            balance: balance,
            rate: rate,
            imageRepresentation: imageRepresentation
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayBalanceUpdated(viewModel: viewModel)
        }
    }
}
