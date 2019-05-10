import UIKit
import Charts

protocol SaleDetailsDisplayLogic: class {
    
    typealias Event = SaleDetails.Event
    
    func displayTabsUpdated(viewModel: Event.TabsUpdated.ViewModel)
    func displaySelectBalance(viewModel: Event.SelectBalance.ViewModel)
    func displayBalanceSelected(viewModel: Event.BalanceSelected.ViewModel)
    func displayInvestAction(viewModel: Event.InvestAction.ViewModel)
    func displayCancelInvestAction(viewModel: Event.CancelInvestAction.ViewModel)
    func displaySelectChartPeriod(viewModel: Event.SelectChartPeriod.ViewModel)
    func displaySelectChartEntry(viewModel: Event.SelectChartEntry.ViewModel)
    func displayTabWasSelected(viewModel: Event.TabWasSelected.ViewModel)
}

extension SaleDetails {
    
    typealias DisplayLogic = SaleDetailsDisplayLogic
    
    class ViewController: UIViewController {
        
        typealias Event = SaleDetails.Event
        
        // MARK: - Private properties
        
        private let horizontalPicker: HorizontalPicker = HorizontalPicker()
        private let containerView: UIView = UIView()
        private var contentType: Model.TabViewType?
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        
        func inject(interactorDispatch: InteractorDispatch?, routing: Routing?) {
            self.interactorDispatch = interactorDispatch
            self.routing = routing
        }
        
        // MARK: - Overridden
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.setupView()
            self.setupHorizontalPicker()
            self.setupContainerView()
            self.setupLayout()
            
            let request = Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.containerBackgroundColor
        }
        
        private func setupHorizontalPicker() {
            self.horizontalPicker.backgroundColor = Theme.Colors.mainColor
            self.horizontalPicker.tintColor = Theme.Colors.textOnMainColor
        }
        
        private func setupContainerView() {
            self.containerView.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupLayout() {
            self.view.addSubview(self.horizontalPicker)
            self.view.addSubview(self.containerView)
            self.horizontalPicker.snp.makeConstraints { (make) in
                make.leading.trailing.top.equalToSuperview()
            }
            
            self.containerView.snp.makeConstraints { (make) in
                make.leading.trailing.bottom.equalToSuperview()
                make.top.equalTo(self.horizontalPicker.snp.bottom)
            }
        }
        
        private func updateSelectedTabIfNeeded(index: Int?) {
            guard let index = index,
                self.horizontalPicker.selectedItemIndex != index else {
                    return
            }
            self.horizontalPicker.setSelectedItemAtIndex(index, animated: true)
        }
        
        private func setContentView(tabContent: Model.TabContentType) {
            let contentType: Model.TabViewType
            let contentView: UIView
            
            switch tabContent {
                
            case .empty(let viewModel):
                let emptyTabView = SaleDetails.EmptyContent.View()
                viewModel.setup(emptyTabView)
                
                contentType = .empty(emptyTabView)
                contentView = emptyTabView
                
            case .overview(let viewModel):
                let overviewTabView = SaleDetails.OverviewTab.View()
                viewModel.setup(tab: overviewTabView)
                
                contentType = .overview(overviewTabView)
                contentView = overviewTabView
                
            case .details(let viewModel):
                break
                
            case .chart(let viewModel):
                let chartTabView = SaleDetails.ChartTab.View()
                viewModel.setup(tab: chartTabView)
                
                chartTabView.didSelectPickerItem = { [weak self] (period) in
                    let request = Event.SelectChartPeriod.Request(period: period)
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onSelectChartPeriod(request: request)
                    })
                }
                
                chartTabView.didSelectChartItem = { [weak self] (charItemIndex) in
                    let request = Event.SelectChartEntry.Request(chartEntryIndex: charItemIndex)
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onSelectChartEntry(request: request)
                    })
                }
                contentType = .chart(chartTabView)
                contentView = chartTabView
            }
            
            self.removeCurrentTabView()
            self.contentType = contentType
            
            self.containerView.addSubview(contentView)
            contentView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
        
        private func removeCurrentTabView() {
            guard let viewType = self.contentType else {
                return
            }
            
            let view: UIView
            switch viewType {
                
            case .empty(let emptyView):
                view = emptyView
            
            case .overview(let overviewView):
                view = overviewView
                
            case .details(let detailsView):
                view = detailsView
                
            case .chart(let chartView):
                view = chartView
            }
            view.removeFromSuperview()
        }
    }
}

// MARK: - DisplayLogic

extension SaleDetails.ViewController: SaleDetails.DisplayLogic {
    
    func displayTabsUpdated(viewModel: Event.TabsUpdated.ViewModel) {
        let items = viewModel.tabs.map { (tab) -> HorizontalPicker.Item in
            return HorizontalPicker.Item(
                title: tab.title,
                enabled: true,
                onSelect: { [weak self] in
                    let request = Event.TabWasSelected.Request(identifier: tab.id)
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onTabWasSelected(request: request)
                    })
                }
            )
        }
        self.horizontalPicker.items = items
        self.updateSelectedTabIfNeeded(index: viewModel.selectedTabIndex)
        self.setContentView(tabContent: viewModel.selectedTabContent)
    }
    
    func displaySelectBalance(viewModel: Event.SelectBalance.ViewModel) {
        let options: [String] = viewModel.balances.map({ $0.asset })
        self.routing?.onPresentPicker(Localized(.select_asset), options, { [weak self] (selectedIndex) in
            let balance = viewModel.balances[selectedIndex]
            let request = Event.BalanceSelected.Request(balanceId: balance.balanceId)
            self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                businessLogic.onBalanceSelected(request: request)
            })
        })
    }
    
    func displayBalanceSelected(viewModel: Event.BalanceSelected.ViewModel) {
        
    }
    
    func displayInvestAction(viewModel: Event.InvestAction.ViewModel) {
        switch viewModel {
            
        case .loading:
            self.routing?.onShowProgress()
            
        case .loaded:
            self.routing?.onHideProgress()
            
        case .failed(let message):
            self.routing?.onShowError(message)
            
        case .succeeded(let saleInvestModel):
            self.routing?.onSaleInvestAction(saleInvestModel)
        }
    }
    
    func displayCancelInvestAction(viewModel: Event.CancelInvestAction.ViewModel) {
        switch viewModel {
            
        case .loading:
            self.routing?.onShowProgress()
            
        case .succeeded:
            self.routing?.onHideProgress()
            
        case .failed(let message):
            self.routing?.onHideProgress()
            self.routing?.onShowError(message)
        }
    }
    
    func displaySelectChartPeriod(viewModel: Event.SelectChartPeriod.ViewModel) {
        guard let viewType = self.contentType else {
            return
        }
        switch viewType {
            
        case .chart(let chartTab):
            viewModel.viewModel.setup(tab: chartTab)
            
        default:
            break
        }
    }
    
    func displaySelectChartEntry(viewModel: Event.SelectChartEntry.ViewModel) {
        guard let viewType = self.contentType else {
            return
        }
        switch viewType {
            
        case .chart(let chartTab):
            viewModel.viewModel.setup(tab: chartTab)
            
        default:
            break
        }
    }
    
    func displayTabWasSelected(viewModel: Event.TabWasSelected.ViewModel) {
        self.setContentView(tabContent: viewModel.tabContent)
    }
}
