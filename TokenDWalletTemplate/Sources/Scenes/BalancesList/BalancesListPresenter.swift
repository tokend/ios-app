import UIKit

public protocol BalancesListPresentationLogic {
    typealias Event = BalancesList.Event
    
    func presentSectionsUpdated(response: Event.SectionsUpdated.Response)
    func presentLoadingStatusDidChange(response: Event.LoadingStatusDidChange.Response)
    func presentPieChartEntriesChanged(response: Event.PieChartEntriesChanged.Response)
    func presentPieChartBalanceSelected(response: Event.PieChartBalanceSelected.Response)
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
        private let percentFormatter: PercentFormatterProtocol
        private let colorsProvider: PieChartColorsProviderProtocol
        
        // MARK: -
        
        init(
            presenterDispatch: PresenterDispatch,
            amountFormatter: AmountFormatterProtocol,
            percentFormatter: PercentFormatterProtocol,
            colorsProvider: PieChartColorsProviderProtocol
            ) {
            
            self.presenterDispatch = presenterDispatch
            self.amountFormatter = amountFormatter
            self.percentFormatter = percentFormatter
            self.colorsProvider = colorsProvider
        }
        
        // MARK: - Private
        
        private func getChartViewModel(model: Model.PieChartModel) -> Model.PieChartViewModel {
            var highlightedEntry: Model.HighlightedEntryViewModel?
            if let highlightedEntryModel = model.highlitedEntry {
                let percent = self.percentFormatter.formatPercantage(
                    percent: highlightedEntryModel.value
                )
                highlightedEntry = Model.HighlightedEntryViewModel(
                    index: Double(highlightedEntryModel.index),
                    value: NSAttributedString(string: percent)
                )
            }
            let colorsPallete = self.colorsProvider.getDefaultPieChartColors()
            
            return Model.PieChartViewModel(
                entries: model.entries,
                highlitedEntry: highlightedEntry,
                colorsPallete: colorsPallete
            )
        }
        
        private func getLegendCellViewModels(
            cells: [Model.LegendCellModel],
            convertedAsset: String
            ) -> [LegendCell.ViewModel] {
            
            let cellViewModels = cells.map { (cell) -> LegendCell.ViewModel in
                var assetName: String
                var indicatorColor: UIColor = Theme.Colors.contentBackgroundColor
                switch cell.balanceType {
                    
                case .balance:
                    assetName = cell.assetName
                    
                case .other:
                    assetName = Localized(.other)
                    indicatorColor = self.colorsProvider.getPieChartColorForOther()
                }
                
                let balance = self.amountFormatter.formatAmount(
                    cell.balance,
                    currency: convertedAsset
                )
                
                if let cellIndex = cells.indexOf(cell) {
                    let colorsPallete = self.colorsProvider.getDefaultPieChartColors()
                    indicatorColor = colorsPallete[cellIndex]
                }
                
                return LegendCell.ViewModel(
                    assetName: assetName,
                    balance: balance,
                    isSelected: cell.isSelected,
                    indicatorColor: indicatorColor,
                    percentageValue: cell.balancePercentage
                )
            }
            return cellViewModels
        }
    }
}

extension BalancesList.Presenter: BalancesList.PresentationLogic {
    
    public func presentSectionsUpdated(response: Event.SectionsUpdated.Response) {
        let sections = response.sections.map { (section) -> Model.SectionViewModel in
            let cells = section.cells.map({ (cell) -> CellViewAnyModel in
                switch cell {
                    
                case .balance(let balanceModel):
                    let balance = self.amountFormatter.formatAmount(
                        balanceModel.balance,
                        currency: balanceModel.code
                    )
                    
                    let abbreviationBackgroundColor = TokenColoringProvider.shared.coloringForCode(balanceModel.code)
                    let abbreviation = balanceModel.code.first
                    let abbreviationText = abbreviation?.description ?? ""
                    
                    var imageRepresentation = Model.ImageRepresentation.abbreviation
                    if let url = balanceModel.iconUrl {
                        imageRepresentation = .image(url)
                    }
                    let balanceViewModel = BalancesList.BalanceCell.ViewModel(
                        code: balanceModel.code,
                        imageRepresentation: imageRepresentation,
                        balance: balance,
                        abbreviationBackgroundColor: abbreviationBackgroundColor,
                        abbreviationText: abbreviationText,
                        balanceId: balanceModel.balanceId,
                        cellIdentifier: .balances
                    )
                    return balanceViewModel
                    
                case .header(let headerModel):
                    let balanceTitle = self.amountFormatter.formatAmount(
                        headerModel.balance,
                        currency: headerModel.asset
                    )
                    let headerModel = BalancesList.HeaderCell.ViewModel(
                        balance: balanceTitle,
                        cellIdentifier: .header
                        )
                    return headerModel
                    
                case .chart(let pieChartModel):
                    let pieChartViewModel = self.getChartViewModel(model: pieChartModel)
                    let legendCells = self.getLegendCellViewModels(
                        cells: pieChartModel.legendCells,
                        convertedAsset: pieChartModel.convertAsset
                    )
                    let chartViewModel = BalancesList.PieChartCell.ViewModel(
                        chartViewModel: pieChartViewModel,
                        legendCells: legendCells,
                        cellIdentifier: .chart
                    )
                    return chartViewModel
                }
            })
            return Model.SectionViewModel(cells: cells)
        }
        
        let viewModel = Event.SectionsUpdated.ViewModel(sections: sections)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySectionsUpdated(viewModel: viewModel)
        }
    }
    
    public func presentLoadingStatusDidChange(response: Event.LoadingStatusDidChange.Response) {
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayLoadingStatusDidChange(viewModel: viewModel)
        }
    }
    
    public func presentPieChartEntriesChanged(response: Event.PieChartEntriesChanged.Response) {
        var highlightedEntry: Model.HighlightedEntryViewModel?
        if let highLightedEntryModel = response.model.highlitedEntry {
            let value = highLightedEntryModel.value.rounded()
            let string = "\(Int(value))%"
            highlightedEntry = Model.HighlightedEntryViewModel(
                index: Double(highLightedEntryModel.index),
                value: NSAttributedString(string: string)
            )
        }
        let colorsPallete = self.colorsProvider.getDefaultPieChartColors()
        
        let model = Model.PieChartViewModel(
            entries: response.model.entries,
            highlitedEntry: highlightedEntry,
            colorsPallete: colorsPallete
        )
        let viewModel = Event.PieChartEntriesChanged.ViewModel(model: model)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayPieChartEntriesChanged(viewModel: viewModel)
        }
    }
    
    public func presentPieChartBalanceSelected(response: Event.PieChartBalanceSelected.Response) {
        let pieChartViewModel = self.getChartViewModel(model: response.pieChartModel)
        let legendCells = self.getLegendCellViewModels(
            cells: response.legendCells,
            convertedAsset: response.pieChartModel.convertAsset
        )
        let viewModel = Event.PieChartBalanceSelected.ViewModel(
            pieChartViewModel: pieChartViewModel,
            legendCells: legendCells
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayPieChartBalanceSelected(viewModel: viewModel)
        }
    }
}
