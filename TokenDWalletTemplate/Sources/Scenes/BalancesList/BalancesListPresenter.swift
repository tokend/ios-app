import Foundation

public protocol BalancesListPresentationLogic {
    typealias Event = BalancesList.Event
    
    func presentCellsWasChanged(response: Event.CellsWasUpdated.Response)
}

extension BalancesList {
    public typealias PresentationLogic = BalancesListPresentationLogic
    
    @objc(BalancesListPresenter)
    public class Presenter: NSObject {
        
        public typealias Event = BalancesList.Event
        public typealias Model = BalancesList.Model
        
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

extension BalancesList.Presenter: BalancesList.PresentationLogic {
    
    public func presentCellsWasChanged(response: Event.CellsWasUpdated.Response) {
        let sections = response.sections.map { (section) -> Model.SectionViewModel in
            let cells = section.cells.map({ (cell) -> Model.CellViewModel in
                switch cell {
                    
                case .balance(let balanceModel):
                    let balance = self.amountFormatter.formatAmount(
                        balanceModel.convertedBalance,
                        currency: balanceModel.code
                    )
                    
                    let abbreviationBackgroundColor = TokenColoringProvider.shared.coloringForCode(balanceModel.code)
                    let abbreviation = balanceModel.code.first
                    let abbreviationText = abbreviation?.description ?? ""
                    
                    let balanceViewModel = BalancesList.BalanceCell.ViewModel(
                        code: balanceModel.code,
                        balance: balance,
                        abbreviationBackgroundColor: abbreviationBackgroundColor,
                        abbreviationText: abbreviationText,
                        balanceId: balanceModel.balanceId
                    )
                    return .balance(balanceViewModel)
                    
                case .header(let headerModel):
                    let balanceTitle = self.amountFormatter.formatAmount(
                        headerModel.balance,
                        currency: headerModel.asset
                    )
                    let headerModel = BalancesList.HeaderCell.ViewModel(balance: balanceTitle)
                    return .header(headerModel)
                }
            })
            return Model.SectionViewModel(cells: cells)
        }
        
        let viewModel = Event.CellsWasUpdated.ViewModel(sections: sections)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayCellsWasUpdated(viewModel: viewModel)
        }
    }
}
