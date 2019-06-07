import Foundation
import RxSwift

public protocol BalancesListBusinessLogic {
    typealias Event = BalancesList.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onPieChartBalanceSelected(request: Event.PieChartBalanceSelected.Request)
}

extension BalancesList {
    public typealias BusinessLogic = BalancesListBusinessLogic
    
    @objc(BalancesListInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = BalancesList.Event
        public typealias Model = BalancesList.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private var sceneModel: Model.SceneModel
        private let balancesFetcher: BalancesFetcherProtocol
        
        private let displayEntriesCount: Int = 3
        private let disposeBag: DisposeBag = DisposeBag()
        
        // MARK: -
        
        init(
            presenter: PresentationLogic,
            sceneModel: Model.SceneModel,
            balancesFetcher: BalancesFetcherProtocol
            ) {
            
            self.presenter = presenter
            self.sceneModel = sceneModel
            self.balancesFetcher = balancesFetcher
        }
        
        // MARK: - Private
        
        private func updateSections() {
            let headerSection = self.getHeaderSectionModel()
            let chartSection = self.getChartSectionModel()
            let balancesSection = self.getBalancesSectionModel()
            
            let response = Event.SectionsUpdated.Response(
                sections: [
                    headerSection,
                    chartSection,
                    balancesSection
                ]
            )
            self.presenter.presentSectionsUpdated(response: response)
        }
        
        // MARK: - Header
        
        private func getHeaderSectionModel() -> Model.SectionModel {
            let convertedBalance = self.sceneModel.balances
                .reduce(0) { (convertedAmount, balance) -> Decimal in
                    return convertedAmount + balance.convertedBalance
            }
            
            let headerModel = Model.Header(
                balance: convertedBalance,
                asset: self.sceneModel.convertedAsset,
                cellIdentifier: .header
            )
            let headerCell = Model.CellModel.header(headerModel)
            return Model.SectionModel(cells: [headerCell])
        }
        
        // MARK: - Balances
        
        private func getBalancesSectionModel() -> Model.SectionModel {
            var cells: [Model.CellModel] = []
            self.sceneModel.balances.forEach { (balance) in
                cells.append(.balance(balance))
            }
            return Model.SectionModel(cells: cells)
        }
        
        // MARK: - Charts
        
        private func updateChartBalances() {
            let balances = self.sceneModel.balances
            var chartBalances: [Model.ChartBalance] = []
            balances.takeFirst(n: self.displayEntriesCount)
                .forEach({ (balance) in
                    let balancePercentage = self.getBalancePercentage(
                        convertedBalance: balance.convertedBalance
                    )
                    let chartBalance = Model.ChartBalance(
                        assetName: balance.assetName,
                        balanceId: balance.balanceId,
                        convertedBalance: balance.convertedBalance,
                        balancePercentage: balancePercentage,
                        type: .balance
                    )
                    chartBalances.append(chartBalance)
                })
            if balances.count == self.displayEntriesCount + 1 {
                let lastBalance = balances[self.displayEntriesCount]
                let balancePercentage = self.getBalancePercentage(
                    convertedBalance: lastBalance.convertedBalance
                )
                let chartBalance = Model.ChartBalance(
                    assetName: lastBalance.assetName,
                    balanceId: lastBalance.balanceId,
                    convertedBalance: lastBalance.convertedBalance,
                    balancePercentage: balancePercentage,
                    type: .balance
                )
                chartBalances.append(chartBalance)
            } else if balances.count > self.displayEntriesCount + 1 {
                let otherBalancesValue = balances[self.displayEntriesCount...balances.count-1]
                    .reduce(0) { (amount, balance) -> Decimal in
                        return amount + balance.convertedBalance
                }
                let balancesPercentage = self.getBalancePercentage(
                    convertedBalance: otherBalancesValue
                )
                let chartBalance = Model.ChartBalance(
                    assetName: "",
                    balanceId: "",
                    convertedBalance: otherBalancesValue,
                    balancePercentage: balancesPercentage,
                    type: .other
                )
                chartBalances.append(chartBalance)
            }
            self.sceneModel.chartBalances = chartBalances
            self.updateSelectedBalance()
        }
        
        private func updateSelectedBalance() {
            guard let selectedBalance = self.sceneModel.selectedChartBalance else {
                self.sceneModel.selectedChartBalance = self.sceneModel.chartBalances.first
                return
            }
            
            if !self.sceneModel.chartBalances.contains(where: { (balance) -> Bool in
                return balance.balanceId == selectedBalance.balanceId
            }) {
                self.sceneModel.selectedChartBalance = self.sceneModel.chartBalances.first
            }
        }
        
        private func setSelectedChartBalance(totalPercantage: Double) {
            guard let chartBalance = self.sceneModel.chartBalances.first(where: { (balance) -> Bool in
                return balance.balancePercentage == totalPercantage
            }) else {
                return
            }
            
            self.sceneModel.selectedChartBalance = chartBalance
        }
        
        private func getChartSectionModel() -> Model.SectionModel {
            let model = self.getChartModel()
            let cell = Model.CellModel.chart(model)
            return Model.SectionModel(cells: [cell])
        }
        
        private func getChartModel() -> Model.PieChartModel {
            let entries = self.sceneModel.chartBalances.map { (balance) -> Model.PieChartEntry in
                
                return Model.PieChartEntry(value: balance.balancePercentage)
            }
            let legendCells = self.getLegendCellModels()
            let highlitedEntry = self.getHighLightedEntryModel()
            let model = Model.PieChartModel(
                entries: entries,
                legendCells: legendCells,
                highlitedEntry: highlitedEntry,
                convertAsset: self.sceneModel.convertedAsset
            )
            return model
        }
        
        private func getLegendCellModels() -> [Model.LegendCellModel] {
            let cells = self.sceneModel.chartBalances.map { (balance) -> Model.LegendCellModel in
                var isSelected = false
                if let selectedBalance = self.sceneModel.selectedChartBalance {
                    isSelected = balance == selectedBalance
                }
                
                return Model.LegendCellModel(
                    assetName: balance.assetName,
                    balance: balance.convertedBalance,
                    isSelected: isSelected,
                    balancePercentage: balance.balancePercentage,
                    balanceType: balance.type
                )
            }
            return cells
        }
        
        private func getHighLightedEntryModel() -> Model.HighlightedEntryModel? {
            guard let selectedBalance = self.sceneModel.selectedChartBalance,
                let entryIndex = self.sceneModel.chartBalances.indexOf(selectedBalance)
                else {
                    return nil
            }
            return Model.HighlightedEntryModel(
                index: entryIndex,
                value: self.sceneModel.chartBalances[entryIndex].balancePercentage
            )
        }
        
        private func getBalancePercentage(convertedBalance: Decimal) -> Double {
            let totalConvertedAmount = self.sceneModel.balances.reduce(0) { (total, balance) -> Decimal in
                return total + balance.convertedBalance
            }
            let percentageDecimal = (convertedBalance / totalConvertedAmount) * 100
            let percentage = NSDecimalNumber(decimal: percentageDecimal).doubleValue
            return percentage
        }
    }
}

extension BalancesList.Interactor: BalancesList.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        self.balancesFetcher
            .observeLoadingStatus()
            .subscribe(onNext: { [weak self] (status) in
                self?.presenter.presentLoadingStatusDidChange(response: status)
            })
            .disposed(by: self.disposeBag)
        
        self.balancesFetcher
            .observeBalances()
            .subscribe(onNext: { [weak self] (balances) in
                self?.sceneModel.balances = balances
                self?.updateChartBalances()
                self?.updateSections()
            })
            .disposed(by: self.disposeBag)
    }
    
    public func onPieChartBalanceSelected(request: Event.PieChartBalanceSelected.Request) {
        self.setSelectedChartBalance(totalPercantage: request.value)
        let pieChartModel = self.getChartModel()
        let legendCells = self.getLegendCellModels()
        let response = Event.PieChartBalanceSelected.Response(
            pieChartModel: pieChartModel,
            legendCells: legendCells
        )
        self.presenter.presentPieChartBalanceSelected(response: response)
    }
}
