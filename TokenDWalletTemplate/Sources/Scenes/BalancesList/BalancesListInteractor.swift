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
        
        private func getChartSectionModel() -> Model.SectionModel {
            let model = self.getChartModel()
            let cell = Model.CellModel.chart(model)
            return Model.SectionModel(cells: [cell])
        }
        
        private func getChartModel() -> Model.PieChartModel {
            let balances = self.sceneModel.balances
            let totalConvertedAmount = balances.reduce(0) { (total, balance) -> Decimal in
                return total + balance.convertedBalance
            }
            var chartBalances: [Model.ChartBalance] = []
            var entries = balances.takeFirst(n: self.displayEntriesCount)
                .map({ (balance) -> Model.PieChartEntry in
                    let entry = self.convertToPieChartEntry(
                        convertedBalance: balance.convertedBalance,
                        total: totalConvertedAmount
                    )
                    let chartBalance = Model.ChartBalance(
                        assetName: balance.assetName,
                        balanceId: balance.balanceId,
                        convertedBalance: balance.convertedBalance,
                        totalPercanatge: entry.value,
                        type: .balance
                    )
                    chartBalances.append(chartBalance)
                    return entry
                })
            if balances.count == self.displayEntriesCount + 1 {
                let lastBalance = balances[self.displayEntriesCount]
                let lastEntry = self.convertToPieChartEntry(
                    convertedBalance: lastBalance.convertedBalance,
                    total: totalConvertedAmount
                )
                let chartBalance = Model.ChartBalance(
                    assetName: lastBalance.assetName,
                    balanceId: lastBalance.balanceId,
                    convertedBalance: lastBalance.convertedBalance,
                    totalPercanatge: lastEntry.value,
                    type: .balance
                )
                entries.append(lastEntry)
                chartBalances.append(chartBalance)
            } else if balances.count > self.displayEntriesCount + 1 {
                let otherBalancesValue = balances[self.displayEntriesCount...balances.count-1]
                    .reduce(0) { (amount, balance) -> Decimal in
                        return amount + balance.convertedBalance
                }
                let otherBalanciesEntry = self.convertToPieChartEntry(
                    convertedBalance: otherBalancesValue,
                    total: totalConvertedAmount
                )
                let chartBalance = Model.ChartBalance(
                    assetName: "",
                    balanceId: "",
                    convertedBalance: otherBalancesValue,
                    totalPercanatge: otherBalanciesEntry.value,
                    type: .other
                )
                entries.append(otherBalanciesEntry)
                chartBalances.append(chartBalance)
            }
            self.sceneModel.chartBalances = chartBalances
            self.updateSelectedBalance()
            
            let highlitedEntry = self.getHighLightedEntryModel()
            let model = Model.PieChartModel(
                entries: entries,
                highlitedEntry: highlitedEntry
            )
            return model
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
                return balance.totalPercanatge == totalPercantage
            }) else {
                return
            }
            
            self.sceneModel.selectedChartBalance = chartBalance
        }
        
        private func getHighLightedEntryModel() -> Model.HighlightedEntryModel? {
            guard let selectedBalance = self.sceneModel.selectedChartBalance,
                let entryIndex = self.sceneModel.chartBalances.indexOf(selectedBalance)
                else {
                    return nil
            }
            return Model.HighlightedEntryModel(
                index: entryIndex,
                value: self.sceneModel.chartBalances[entryIndex].totalPercanatge
            )
        }
        
        private func convertToPieChartEntry(convertedBalance: Decimal, total: Decimal) -> Model.PieChartEntry {
            let percentageDecimal = (convertedBalance / total) * 100
            let percentage = NSDecimalNumber(decimal: percentageDecimal).doubleValue
            return Model.PieChartEntry(value: percentage)
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
                self?.updateSections()
            })
            .disposed(by: self.disposeBag)
    }
    
    public func onPieChartBalanceSelected(request: Event.PieChartBalanceSelected.Request) {
        self.setSelectedChartBalance(totalPercantage: request.value)
        let pieChartModel = self.getChartModel()
        let response = Event.PieChartBalanceSelected.Response(model: pieChartModel)
        self.presenter.presentPieChartBalanceSelected(response: response)
    }
}
