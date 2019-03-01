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
        
        private func transformToViewModels(models: [Model.FeeModel]) -> [Model.SectionViewModel] {
            var sections: [Model.SectionViewModel] = []
            
            for model in models {
                var viewModels: [Fees.TitleValueViewModel] = []
                
                if let subtype = model.subtype {
                    let subtypeCell = Fees.TitleValueViewModel(
                        title: Localized(.subtype),
                        identifier: .subtype,
                        value: self.feeDataFormatter.formatSubtype(subtype: subtype)
                    )
                    viewModels.append(subtypeCell)
                }
                
                let fixedCell = Fees.TitleValueViewModel(
                    title: Localized(.fixed),
                    identifier: .fixed,
                    value: self.feeDataFormatter.format(asset: model.feeAsset, value: model.fixed)
                )
                viewModels.append(fixedCell)
                
                let percentCell = Fees.TitleValueViewModel(
                    title: Localized(.percent),
                    identifier: .percent,
                    value: self.feeDataFormatter.formatPercent(value: model.percent)
                )
                viewModels.append(percentCell)
                
                let lowerBoundCell = Fees.TitleValueViewModel(
                    title: Localized(.lower_bound),
                    identifier: .lowerBound,
                    value: self.feeDataFormatter.format(asset: model.asset, value: model.lowerBound)
                )
                viewModels.append(lowerBoundCell)
                
                let upperBoundCell = Fees.TitleValueViewModel(
                    title: Localized(.upper_bound),
                    identifier: .upperBound,
                    value: self.feeDataFormatter.format(asset: model.asset, value: model.upperBound)
                )
                viewModels.append(upperBoundCell)
                
                let title: String
                
                if let feeType = model.feeType {
                    title = self.feeDataFormatter.formatFeeType(feeType: feeType)
                } else {
                    title = Localized(.undefined)
                }
                
                let section = Model.SectionViewModel(
                    title: title,
                    cells: viewModels
                )
                sections.append(section)
            }
            
            return sections
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
        let sections = self.transformToViewModels(models: response.fees)
        let viewModel = Event.TabsDidUpdate.ViewModel(
            titles: response.titles,
            sections: sections,
            selectedTabIndex: response.selectedTabIndex
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayTabsDidUpdate(viewModel: viewModel)
        }
    }
    
    func presentTabWasSelected(response: Event.TabWasSelected.Response) {
        let sections: [Model.SectionViewModel] = self.transformToViewModels(models: response.models)
        
        let viewModel = Event.TabWasSelected.ViewModel(sections: sections)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayTabWasSelected(viewModel: viewModel)
        }
    }
}
