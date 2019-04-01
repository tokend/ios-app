// swiftlint:disable file_length
import Foundation
import TokenDSDK
import RxSwift
import RxCocoa

protocol SaleDetailsBusinessLogic {
    typealias Event = SaleDetails.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onSelectBalance(request: Event.SelectBalance.Request)
    func onBalanceSelected(request: Event.BalanceSelected.Request)
    func onInvestAction(request: Event.InvestAction.Request)
    func onCancelInvestAction(request: Event.CancelInvestAction.Request)
    func onEditAmount(request: Event.EditAmount.Request)
    func onDidSelectMoreInfoButton(request: Event.DidSelectMoreInfoButton.Request)
    func onSelectChartPeriod(request: Event.SelectChartPeriod.Request)
    func onSelectChartEntry(request: Event.SelectChartEntry.Request)
}

extension SaleDetails {
    typealias BusinessLogic = SaleDetailsBusinessLogic
    
    class Interactor {
        
        typealias Event = SaleDetails.Event
        typealias Model = SaleDetails.Model
        
        private let presenter: PresentationLogic
        private let dataProvider: DataProvider
        private let feeLoader: FeeLoader
        private let cancelInvestWorker: CancelInvestWorkerProtocol
        private let investorAccountId: String
        
        private let sceneModel: Model.SceneModel = Model.SceneModel()
        
        private let queue: DispatchQueue = DispatchQueue(
            label: NSStringFromClass(Interactor.self).queueLabel,
            qos: .userInteractive
        )
        private let updateRelay: BehaviorRelay<Bool> = BehaviorRelay(value: true)
        
        private var sale: Model.SaleModel? {
            didSet {
                self.updateRelay.emitEvent()
                
                self.observeAsset()
                self.observeSaleBalance()
            }
        }
        private var saleBalance: Model.BalanceDetails?
        private var assetModel: Model.AssetModel? {
            didSet {
                self.updateRelay.emitEvent()
            }
        }
        private var balances: [Model.BalanceDetails] = [] {
            didSet {
                self.updateSelectedBalance()
                self.updateRelay.emitEvent()
            }
        }
        private var account: Model.AccountModel? {
            didSet {
                self.updateRelay.emitEvent()
            }
        }
        private var offers: [Model.InvestmentOffer] = [] {
            didSet {
                self.updateSelectedBalance()
                self.updateRelay.emitEvent()
            }
        }
        private var charts: [Model.Period: [Model.ChartEntry]] = [:] {
            didSet {
                self.updateChartsPeriods()
                self.updateRelay.emitEvent()
            }
        }
        
        private var assetDisposable: Disposable? {
            willSet {
                self.assetDisposable?.dispose()
            }
        }
        
        private var saleBalanceDisposable: Disposable? {
            willSet {
                self.saleBalanceDisposable?.dispose()
            }
        }
        
        private var offersDisposable: Disposable? {
            willSet {
                self.offersDisposable?.dispose()
            }
        }
        
        private let disposeBag = DisposeBag()
        
        init(
            presenter: PresentationLogic,
            dataProvider: DataProvider,
            feeLoader: FeeLoader,
            cancelInvestWorker: CancelInvestWorkerProtocol,
            investorAccountId: String
            ) {
            
            self.dataProvider = dataProvider
            self.presenter = presenter
            self.feeLoader = feeLoader
            self.cancelInvestWorker = cancelInvestWorker
            self.investorAccountId = investorAccountId
        }
        
        // MARK: - Private
        
        private func updateSections() {
            self.sceneModel.sections = self.createSections()
            
            let response = Event.SectionsUpdated.Response(sections: self.sceneModel.sections)
            self.presenter.presentSectionsUpdated(response: response)
        }
        
        private func createSections() -> [Model.SectionModel] {
            var sections: [Model.SectionModel] = []
            
            guard let sale = self.sale else {
                return sections
            }
            
            // Description
            
            let investmentPercentage: Float
            if sale.softCap != 0.0 {
                investmentPercentage = Float(truncating: sale.currentCap / sale.softCap as NSNumber)
            } else {
                investmentPercentage = 1.0
            }
            
            let descModel = Model.DescriptionCellModel(
                imageUrl: sale.details.logoUrl,
                name: sale.details.name,
                description: sale.details.shortDescription,
                asset: sale.baseAsset,
                investmentAsset: sale.defaultQuoteAsset,
                investmentAmount: sale.currentCap,
                investmentPercentage: investmentPercentage,
                investorsCount: sale.investorsCount,
                startDate: sale.startTime,
                endDate: sale.endTime,
                youtubeVideoUrl: sale.details.youtubeVideoUrl,
                cellIdentifier: .description
            )
            
            let descCellModel = Model.CellModel(cellType: .description(descModel))
            let descSection = Model.SectionModel(cells: [descCellModel])
            sections.append(descSection)
            
            // Invest
            
            let investingEnabled: Bool
            if self.account != nil, self.assetModel != nil {
                investingEnabled = true
            } else {
                investingEnabled = false
            }
            
            if investingEnabled {
                let investingModel = self.getInvestingCellModel()
                
                let investingCellModel = Model.CellModel(cellType: .investing(investingModel))
                let investingSection = Model.SectionModel(cells: [investingCellModel])
                sections.append(investingSection)
            }
            
            // Chart
            
            if let selected = self.sceneModel.selectedChartsPeriod,
                let charts = self.getChartsForPeriod(selected),
                let lastChart = charts.last {
                
                let chartCellModel = self.getChartCellModel(
                    charts: charts,
                    chart: lastChart,
                    sale: sale
                )
                
                let chartCell = Model.CellModel(cellType: .chart(chartCellModel))
                
                let chartSection = Model.SectionModel(cells: [chartCell])
                sections.append(chartSection)
            }
            
            return sections
        }
        
        private func getInvestingCellModel() -> Model.InvestingCellModel {
            let availableAmount = self.getAvailableInputAmount()
            let isCancellable = self.sceneModel.inputAmount != 0.0
            
            let investingModel = Model.InvestingCellModel(
                selectedBalance: self.sceneModel.selectedBalance,
                amount: self.sceneModel.inputAmount,
                availableAmount: availableAmount,
                isCancellable: isCancellable,
                cellIdentifier: .investing
            )
            
            return investingModel
        }
        
        private func getChartCellModel(
            charts: [Model.ChartEntry],
            chart: Model.ChartEntry,
            sale: Model.SaleModel
            ) -> Model.ChartCellModel {
            
            let investedAmount = chart.value
            let investedDate: Date? = self.sceneModel.selectedChartEntryIndex == nil ? nil : chart.date
            let datePickerItems = self.sceneModel.chartsPeriods
            let selectedDatePickerItem = self.getSelectedPeriodIndex()
            let growth = self.getChartGrowthForCharts(charts)
            let growthPositive: Bool? = growth == 0.0 ? nil : growth > 0.0
            var growthSincePeriod: Model.Period?
            if let selectedPeriod = selectedDatePickerItem {
                growthSincePeriod = datePickerItems[selectedPeriod]
            }
            let chartModel = self.getChartModel(charts: charts)
            
            let chartCellModel = Model.ChartCellModel(
                asset: sale.defaultQuoteAsset,
                investedAmount: investedAmount,
                investedDate: investedDate,
                datePickerItems: datePickerItems,
                selectedDatePickerItem: selectedDatePickerItem,
                growth: growth,
                growthPositive: growthPositive,
                growthSincePeriod: growthSincePeriod,
                chartModel: chartModel,
                cellIdentifier: .charts
            )
            
            return chartCellModel
        }
        
        private func getChartGrowthForCharts(_ charts: [Model.ChartEntry]) -> Decimal {
            guard let first = charts.first, let last = charts.last else {
                return 0.0
            }
            
            let growth = last.value - first.value
            
            return growth
        }
        
        private func observeAsset() {
            guard let assetCode = self.sale?.baseAsset else {
                self.assetDisposable = nil
                return
            }
            
            self.assetDisposable = self.dataProvider
                .observeAsset(assetCode: assetCode)
                .subscribe(onNext: { [weak self] (asset) in
                    self?.assetModel = asset
                })
        }
        
        private func observeSaleBalance() {
            guard let sale = self.sale else {
                self.saleBalanceDisposable = nil
                return
            }
            
            self.saleBalanceDisposable = self.dataProvider
                .observeBalances()
                .map({ (balances) -> Model.BalanceDetails? in
                    return balances.first(where: { (balance) -> Bool in
                        balance.asset == sale.baseAsset
                    })
                })
                .subscribe(onNext: { [weak self] (optionalBalance) in
                    self?.saleBalance = optionalBalance
                })
        }
        
        private func observeOffers() {
            self.offersDisposable = self.dataProvider
                .observeOffers()
                .subscribe(onNext: { [weak self] (offers) in
                    self?.offers = offers
                })
        }
        
        private func getBalanceWith(balanceId: String) -> Model.BalanceDetails? {
            return self.balances.first(where: { (balanceDetails) in
                return balanceDetails.balanceId == balanceId
            })
        }
        
        private func filterQuoteBalances(from balances: [Model.BalanceDetails]) -> [Model.BalanceDetails] {
            guard let sale = self.sale, sale.quoteAssets.count > 0, balances.count > 0 else {
                return []
            }
            
            var filtered: [Model.BalanceDetails] = []
            
            for balance in balances {
                if sale.quoteAssets.contains(where: { quoteAsset in
                    return balance.asset == quoteAsset.asset
                }) {
                    filtered.append(balance)
                }
            }
            
            let sorted = filtered.sorted { (balance1, balance2) -> Bool in
                return balance1.asset.caseInsensitiveCompare(balance2.asset) == .orderedAscending
            }
            
            return sorted
        }
        
        private func updateSelectedBalance() {
            var shouldUpdateInputAmount = false
            if let selectedBalance = self.sceneModel.selectedBalance {
                if !self.balances.contains(selectedBalance) {
                    self.sceneModel.selectedBalance = nil
                    shouldUpdateInputAmount = true
                }
            }
            
            for balance in self.balances {
                if let prevOffer = self.getPreviousOffer(selectedBalance: balance), prevOffer.amount > 0.0 {
                    self.sceneModel.selectedBalance = balance
                    self.sceneModel.selectedBalance?.prevOfferId = prevOffer.id
                    shouldUpdateInputAmount = true
                    break
                }
            }
            
            if let selectedBalance = self.sceneModel.selectedBalance {
                let prevOfferId = self.getPrevOfferId(selectedBalance: selectedBalance)
                if prevOfferId != selectedBalance.prevOfferId {
                    self.sceneModel.selectedBalance?.prevOfferId = prevOfferId
                    shouldUpdateInputAmount = true
                }
            }
            
            if self.sceneModel.selectedBalance == nil {
                self.sceneModel.selectedBalance = self.balances.first
                shouldUpdateInputAmount = true
            }
            
            if shouldUpdateInputAmount {
                self.updateInputAmountFromSelectedBalance()
            }
        }
        
        private func updateInputAmountFromSelectedBalance() {
            guard let selectedBalance = self.sceneModel.selectedBalance else {
                self.sceneModel.inputAmount = 0.0
                return
            }
            
            guard let prevOffer = self.getPreviousOffer(selectedBalance: selectedBalance) else {
                self.sceneModel.inputAmount = 0.0
                return
            }
            
            self.sceneModel.inputAmount = prevOffer.amount
        }
        
        private func updateChartsPeriods() {
            let periods = self.getPeriodPickerItemsForCharts(self.charts)
            self.sceneModel.chartsPeriods = periods
            
            self.updateSelectedChart()
        }
        
        private func updateSelectedChart() {
            let periods = self.sceneModel.chartsPeriods
            guard periods.count > 0 else {
                self.sceneModel.selectedChartsPeriod = nil
                return
            }
            
            self.sceneModel.selectedChartsPeriod = periods.first
        }
        
        private func getAvailableInputAmount() -> Decimal {
            guard let selectedBalance = self.sceneModel.selectedBalance else {
                return 0.0
            }
            
            var availableInputAmount = selectedBalance.balance
            
            if let prevOffer = self.getPreviousOffer(selectedBalance: selectedBalance) {
                availableInputAmount += prevOffer.amount
            }
            
            return availableInputAmount
        }
        
        private func loadFee(
            asset: Model.SaleModel.QuoteAsset,
            investAmount: Decimal,
            completion: @escaping (FeeResult) -> Void
            ) {
            
            self.feeLoader.loadFee(
                accountId: self.investorAccountId,
                asset: asset.asset,
                feeType: .offerFee,
                amount: investAmount) { (feeResponse) in
                    switch feeResponse {
                        
                    case .succeeded(let response):
                        completion(.success(fee: response))
                        
                    case .failed(let error) :
                        completion(.failed(error: error))
                    }
            }
        }
        
        private func getPreviousOffer(selectedBalance: Model.BalanceDetails) -> Model.InvestmentOffer? {
            guard let prevOffer = self.offers.first(where: { (offer) -> Bool in
                return offer.asset == selectedBalance.asset
            }) else {
                return nil
            }
            
            return prevOffer
        }
        
        private func getPrevOfferId(selectedBalance: Model.BalanceDetails) -> UInt64? {
            guard let prevOffer = self.getPreviousOffer(selectedBalance: selectedBalance) else {
                return nil
            }
            
            return prevOffer.id
        }
        
        private func getChartsForPeriod(_ period: Model.Period) -> [Model.ChartEntry]? {
            return self.charts[period]
        }
        
        private func getPeriodPickerItemsForCharts(_ charts: [Model.Period: [Model.ChartEntry]]) -> [Model.Period] {
            var periods = charts.compactMap({ (chartItem) -> Model.Period? in
                return chartItem.value.count > 0 ? chartItem.key : nil
            })
            
            periods.sort { (period1, period2) -> Bool in
                return period1.rawValue <= period2.rawValue
            }
            
            return periods
        }
        
        private func getSelectedPeriodIndex() -> Int? {
            guard let selected = self.sceneModel.selectedChartsPeriod else {
                return nil
            }
            
            return self.sceneModel.chartsPeriods.index(of: selected)
        }
        
        private func getChartModel(charts: [Model.ChartEntry]) -> Model.ChartModel {
            let chartMaxValue = charts.max { (entry1, entry2) -> Bool in
                return entry1.value < entry2.value
                }?.value ?? 0.0
            let chartModel = Model.ChartModel(
                entries: charts,
                maxValue: chartMaxValue
            )
            
            return chartModel
        }
        
        private func handleCancelInvestAction() {
            guard let sale = self.sale else {
                let response = Event.CancelInvestAction.Response.failed(.saleIsNotFound)
                self.presenter.presentCancelInvestAction(response: response)
                return
            }
            guard let selectedBalance = self.sceneModel.selectedBalance else {
                let response = Event.CancelInvestAction.Response.failed(.quoteBalanceIsNotFound)
                self.presenter.presentCancelInvestAction(response: response)
                return
            }
            
            guard let prevOfferId = self.sceneModel.selectedBalance?.prevOfferId else {
                    let response = Event.CancelInvestAction.Response.failed(.previousOfferIsNotFound)
                    self.presenter.presentCancelInvestAction(response: response)
                    return
            }
            
            guard let quoteAsset = sale.quoteAssets.first(where: { (quoteAsset) -> Bool in
                return quoteAsset.asset == selectedBalance.asset
            }) else {
                let response = Event.CancelInvestAction.Response.failed(.quoteAssetIsNotFound)
                self.presenter.presentCancelInvestAction(response: response)
                return
            }
            
            guard let baseBalance = self.saleBalance else {
                let response = Event.CancelInvestAction.Response.failed(.baseBalanceIsNotFound(asset: sale.baseAsset))
                self.presenter.presentCancelInvestAction(response: response)
                return
            }
            
            guard let orderBookId = UInt64(sale.id) else {
                let response = Event.CancelInvestAction.Response.failed(.formatError)
                self.presenter.presentCancelInvestAction(response: response)
                return
            }
            
            self.loadFee(
                asset: quoteAsset,
                investAmount: 0
            ) { [weak self] (result) in
                switch result {
                    
                case .failed(let error):
                    let response = Event.CancelInvestAction.Response.failed(.feeError(error))
                    self?.presenter.presentCancelInvestAction(response: response)
                    
                case .success(let fee):
                    self?.performCancellation(
                        baseBalance: baseBalance.balanceId,
                        quoteBalance: quoteAsset.quoteBalanceId,
                        price: quoteAsset.price,
                        fee: fee.percent,
                        prevOfferId: prevOfferId,
                        orderBookId: orderBookId
                    )
                }
            }
        }
        
        private func performCancellation(
            baseBalance: String,
            quoteBalance: String,
            price: Decimal,
            fee: Decimal,
            prevOfferId: UInt64,
            orderBookId: UInt64
            ) {
            
            let cancelModel = Model.CancelInvestModel(
                baseBalance: baseBalance,
                quoteBalance: quoteBalance,
                price: price,
                fee: fee,
                prevOfferId: prevOfferId,
                orderBookId: orderBookId
            )
            
            self.cancelInvestWorker.cancelInvest(
                model: cancelModel,
                completion: { [weak self] (result) in
                    
                    let response = Event.CancelInvestAction.Response.loaded
                    self?.presenter.presentCancelInvestAction(response: response)
                    
                    switch result {
                        
                    case .failure:
                        let response = Event.CancelInvestAction.Response.failed(
                            .failedToCancelInvestment
                        )
                        self?.presenter.presentCancelInvestAction(response: response)
                        
                    case .success:
                        self?.observeAsset()
                        self?.observeOffers()
                    }
                }
            )
        }
    }
}

extension SaleDetails.Interactor: SaleDetails.BusinessLogic {
    func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        let scheduler = SerialDispatchQueueScheduler(
            queue: self.queue,
            internalSerialQueueName: self.queue.label
        )
        
        self.updateRelay
            .asObservable()
            .throttle(0.2, scheduler: scheduler)
            .subscribe(onNext: { [weak self] _ in
                self?.updateSections()
            }).disposed(by: self.disposeBag)
        
        self.dataProvider
            .observeSale()
            .subscribe(onNext: { [weak self] (sale) in
                self?.sale = sale
            })
            .disposed(by: self.disposeBag)
        
        self.dataProvider
            .observeBalances()
            .subscribe(onNext: { [weak self] (balances) in
                let filteredBalances: [Model.BalanceDetails]
                if let filtered = self?.filterQuoteBalances(from: balances) {
                    filteredBalances = filtered
                } else {
                    filteredBalances = []
                }
                
                self?.balances = filteredBalances
            })
            .disposed(by: self.disposeBag)
        
        self.dataProvider
            .observeAccount()
            .subscribe(onNext: { [weak self] (account) in
                self?.account = account
            })
            .disposed(by: self.disposeBag)
        
        self.dataProvider
            .observeCharts()
            .subscribe(onNext: { [weak self] (charts) in
                self?.charts = charts
            })
            .disposed(by: self.disposeBag)
        
        self.offersDisposable = self.dataProvider
            .observeOffers()
            .subscribe(onNext: { [weak self] (offers) in
                self?.offers = offers
            })
    }
    
    func onSelectBalance(request: Event.SelectBalance.Request) {
        let response = Event.SelectBalance.Response(balances: self.balances)
        self.presenter.presentSelectBalance(response: response)
    }
    
    func onBalanceSelected(request: Event.BalanceSelected.Request) {
        guard let balance = self.getBalanceWith(balanceId: request.balanceId) else { return }
        
        self.sceneModel.selectedBalance = balance
        self.updateInputAmountFromSelectedBalance()
        
        let investingCellModel = self.getInvestingCellModel()
        let response = Event.BalanceSelected.Response(updatedCell: investingCellModel)
        self.presenter.presentBalanceSelected(response: response)
    }
    
    func onInvestAction(request: Event.InvestAction.Request) {
        let investAmount = self.sceneModel.inputAmount
        
        guard let sale = self.sale else {
            let response = Event.InvestAction.Response.failed(.saleIsNotFound)
            self.presenter.presentInvestAction(response: response)
            return
        }
        guard let selectedBalance = self.sceneModel.selectedBalance else {
            let response = Event.InvestAction.Response.failed(.quoteBalanceIsNotFound)
            self.presenter.presentInvestAction(response: response)
            return
        }
        
        guard let quoteAsset = sale.quoteAssets.first(where: { (quoteAsset) -> Bool in
            return quoteAsset.asset == selectedBalance.asset
        }) else {
            let response = Event.InvestAction.Response.failed(.quoteAssetIsNotFound)
            self.presenter.presentInvestAction(response: response)
            return
        }
        guard investAmount > 0 else {
            let response = Event.InvestAction.Response.failed(.inputIsEmpty)
            self.presenter.presentInvestAction(response: response)
            return
        }
        
        let availableAmount = self.getAvailableInputAmount()
        guard investAmount <= availableAmount else {
            let response = Event.InvestAction.Response.failed(.insufficientFunds)
            self.presenter.presentInvestAction(response: response)
            return
        }
        
        guard let baseBalance = self.saleBalance else {
            let response = Event.InvestAction.Response.failed(.baseBalanceIsNotFound(asset: sale.baseAsset))
            self.presenter.presentInvestAction(response: response)
            return
        }
        
        guard let orderBookId = UInt64(sale.id) else {
            let response = Event.InvestAction.Response.failed(.formatError)
            self.presenter.presentInvestAction(response: response)
            return
        }
        
        self.loadFee(
            asset: quoteAsset,
            investAmount: investAmount) { [weak self] (result) in
                
                switch result {
                    
                case .failed(let error):
                    let response = Event.InvestAction.Response.failed(.feeError(error))
                    self?.presenter.presentInvestAction(response: response)
                    
                case .success(let fee):
                    let prevOfferId = self?.getPrevOfferId(selectedBalance: selectedBalance)
                    let baseAmount = investAmount/quoteAsset.price
                    
                    let saleInvestModel = Model.SaleInvestModel(
                        baseAsset: sale.baseAsset,
                        quoteAsset: quoteAsset.asset,
                        baseBalance: baseBalance.balanceId,
                        quoteBalance: selectedBalance.balanceId,
                        isBuy: true,
                        baseAmount: baseAmount,
                        quoteAmount: investAmount,
                        price: quoteAsset.price,
                        fee: fee.percent,
                        type: sale.type.rawValue,
                        offerId: 0,
                        prevOfferId: prevOfferId,
                        orderBookId: orderBookId
                    )
                    let response = Event.InvestAction.Response.succeeded(saleInvestModel)
                    self?.presenter.presentInvestAction(response: response)
                }
        }
    }
    
    func onCancelInvestAction(request: Event.CancelInvestAction.Request) {
        let response = Event.CancelInvestAction.Response.loading
        self.presenter.presentCancelInvestAction(response: response)
        self.handleCancelInvestAction()
    }
    
    func onEditAmount(request: Event.EditAmount.Request) {
        self.sceneModel.inputAmount = request.amount ?? 0.0
    }
    
    func onDidSelectMoreInfoButton(request: Event.DidSelectMoreInfoButton.Request) {
        guard let sale = self.sale else {
            return
        }
        
        let response = SaleDetails.Event.DidSelectMoreInfoButton.Response(
            saleId: sale.id,
            blobId: sale.details.description,
            asset: sale.baseAsset
        )
        self.presenter.presentDidSelectMoreInfoButton(response: response)
    }
    
    func onSelectChartPeriod(request: Event.SelectChartPeriod.Request) {
        let periods = self.sceneModel.chartsPeriods
        let selectedPeriod = periods[request.period]
        self.sceneModel.selectedChartsPeriod = selectedPeriod
        
        guard
            let sale = self.sale,
            let selectedPeriodIndex = self.getSelectedPeriodIndex(),
            let charts = self.getChartsForPeriod(selectedPeriod),
            let lastChart = charts.last
            else {
                return
        }
        
        let growth = self.getChartGrowthForCharts(charts)
        let growthPositive: Bool? = growth == 0.0 ? nil : growth > 0.0
        
        let updatedCell = self.getChartCellModel(
            charts: charts,
            chart: lastChart,
            sale: sale
        )
        
        let chartModel = self.getChartModel(charts: charts)
        
        let response = Event.SelectChartPeriod.Response(
            asset: sale.defaultQuoteAsset,
            periods: self.sceneModel.chartsPeriods,
            selectedPeriod: selectedPeriod,
            selectedPeriodIndex: selectedPeriodIndex,
            growth: growth,
            growthPositive: growthPositive,
            growthSincePeriod: selectedPeriod,
            chartModel: chartModel,
            updatedCell: updatedCell
        )
        self.presenter.presentSelectChartPeriod(response: response)
    }
    
    func onSelectChartEntry(request: Event.SelectChartEntry.Request) {
        guard
            let sale = self.sale,
            let selectedPeriod = self.sceneModel.selectedChartsPeriod,
            let charts = self.getChartsForPeriod(selectedPeriod),
            let lastChart = charts.last
            else {
                self.sceneModel.selectedChartEntryIndex = nil
                return
        }
        
        self.sceneModel.selectedChartEntryIndex = request.chartEntryIndex
        
        let chart: Model.ChartEntry
        if let selectedChartEntryIndex = self.sceneModel.selectedChartEntryIndex {
            chart = charts[selectedChartEntryIndex]
        } else {
            chart = lastChart
        }
        
        let investedAmount: Decimal = chart.value
        let investedDate: Date? = self.sceneModel.selectedChartEntryIndex == nil ? nil : chart.date
        
        let response = Event.SelectChartEntry.Response(
            asset: sale.defaultQuoteAsset,
            investedAmount: investedAmount,
            investedDate: investedDate,
            identifier: .charts
        )
        self.presenter.presentSelectChartEntry(response: response)
    }
}

extension SaleDetails.Interactor {
    enum FeeResult {
        case failed(error: Swift.Error)
        case success(fee: FeeResponse)
    }
}
// swiftlint:enable file_length
