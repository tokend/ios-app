import Foundation

protocol FeesPresentationLogic {
    typealias Event = Fees.Event
    
    func presentLoadingStatusDidChange(response: Event.LoadingStatusDidChange.Response)
    func presentError(response: Event.Error.Response)
    func presentTabsDidUpdate(response: Event.TabsDidUpdate.Response)
    func presentTabWasSelected(response: Event.TabWasSelected.Response)
}

extension Fees {
    typealias PresentationLogic = FeesPresentationLogic
    
    class Presenter {
        
        typealias Event = Fees.Event
        typealias Model = Fees.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        private let feeDataFormatter: FeeDataFormatterProtocol
        
        // MARK: -
        
        init(
            presenterDispatch: PresenterDispatch,
            feeDataFormatter: FeeDataFormatterProtocol
            ) {
            
            self.presenterDispatch = presenterDispatch
            self.feeDataFormatter = feeDataFormatter
        }
        
        // MARK: - Private
        
        private func transformToViewModels(models: [Model.GroupedFeesModel]) -> [Fees.CardView.CardViewModel] {
            var cards: [Fees.CardView.CardViewModel] = []
            
            for model in models {
                var viewModels: [Fees.FeeCell.ViewModel] = []
                model.feeModels.forEach { (fee) in
                    let bounds = self.feeDataFormatter.formatBounds(
                        lower: fee.lowerBound,
                        upper: fee.upperBound,
                        asset: fee.asset
                    )
                    let fixed = self.feeDataFormatter.format(
                        asset: fee.asset,
                        value: fee.fixed
                    )
                    let percent = self.feeDataFormatter.formatPercent(value: fee.percent)
                    let viewModel = Fees.FeeCell.ViewModel(
                        boundsValue: bounds,
                        fixed: fixed,
                        percent: percent
                    )
                    viewModels.append(viewModel)
                }
                
                let title: String
                
                if let feeType = model.feeType.operationType {
                    title = self.feeDataFormatter.formatFeeType(feeType: feeType)
                } else {
                    title = Localized(.undefined)
                }
                
                let subTitle: String
                if let subtype = model.feeType.subType {
                    subTitle = self.feeDataFormatter.formatSubtype(subtype: subtype)
                } else {
                    subTitle = Localized(.undefined)
                }
                
                let card = Fees.CardView.CardViewModel(
                    title: title,
                    subTitle: subTitle,
                    cells: viewModels
                )
                cards.append(card)
            }
            return cards
        }
    }
}

extension Fees.Presenter: Fees.PresentationLogic {
    
    func presentLoadingStatusDidChange(response: Event.LoadingStatusDidChange.Response) {
        self.presenterDispatch.display { (displayLogic) in
            let viewModel = Event.LoadingStatusDidChange.ViewModel(status: response.status)
            displayLogic.displayLoadingStatusDidChange(viewModel: viewModel)
        }
    }
    
    func presentError(response: Event.Error.Response) {
        let viewModel = Event.Error.ViewModel(message: response.message)
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayError(viewModel: viewModel)
        }
    }
    
    func presentTabsDidUpdate(response: Event.TabsDidUpdate.Response) {
        let cards = self.transformToViewModels(models: response.fees)
        let viewModel = Event.TabsDidUpdate.ViewModel(
            titles: response.titles,
            cards: cards,
            selectedTabIndex: response.selectedTabIndex
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayTabsDidUpdate(viewModel: viewModel)
        }
    }
    
    func presentTabWasSelected(response: Event.TabWasSelected.Response) {
        let cards: [Fees.CardView.CardViewModel] = self.transformToViewModels(models: response.models)
        
        let viewModel = Event.TabWasSelected.ViewModel(cards: cards)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayTabWasSelected(viewModel: viewModel)
        }
    }
}
