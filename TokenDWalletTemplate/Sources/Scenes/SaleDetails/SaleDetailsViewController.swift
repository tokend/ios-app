import UIKit
import Charts

protocol SaleDetailsDisplayLogic: class {
    typealias Event = SaleDetails.Event
    
    func displayTabsUpdated(viewModel: Event.TabsUpdated.ViewModel)
    func displaySelectBalance(viewModel: Event.SelectBalance.ViewModel)
    func displayBalanceSelected(viewModel: Event.BalanceSelected.ViewModel)
    func displayInvestAction(viewModel: Event.InvestAction.ViewModel)
    func displayCancelInvestAction(viewModel: Event.CancelInvestAction.ViewModel)
    func displayDidSelectMoreInfoButton(viewModel: Event.DidSelectMoreInfoButton.ViewModel)
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
        private var contentView: UIView?
        
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
        
        private func updateInvestingTab(_ viewModel: InvestingTab.ViewModel) {
            guard let contentView = self.contentView,
                let investingTab = contentView as? SaleDetails.InvestingTab.View else {
                    return
            }
            viewModel.setup(tab: investingTab)
        }
        
        private func updateSelectedTabIfNeeded(index: Int?) {
            guard let index = index,
                self.horizontalPicker.selectedItemIndex != index else {
                    return
            }
            self.horizontalPicker.setSelectedItemAtIndex(index, animated: true)
        }
        
        private func setContentView(tabContent: Any) {
            let contentView: UIView
            
            if let tabContent = tabContent as? SaleDetails.InvestingTab.ViewModel {
                let investingTabView = SaleDetails.InvestingTab.View()
                tabContent.setup(tab: investingTabView)
                
                investingTabView.onSelectBalance = { [weak self] (identifier) in
                    let request = Event.SelectBalance.Request()
                    self?.interactorDispatch?.sendRequest { businessLogic in
                        businessLogic.onSelectBalance(request: request)
                    }
                }
                investingTabView.onInvestAction = { [weak self] (identifier) in
                    let request = Event.InvestAction.Request()
                    self?.interactorDispatch?.sendRequest { businessLogic in
                        businessLogic.onInvestAction(request: request)
                    }
                }
                investingTabView.onCancelInvestAction = { [weak self] (identifier) in
                    let onSelected: ((Int) -> Void) = { _ in
                        let request = Event.CancelInvestAction.Request()
                        self?.interactorDispatch?.sendRequest { businessLogic in
                            businessLogic.onCancelInvestAction(request: request)
                        }
                    }
                    self?.routing?.showDialog(
                        Localized(.cancel_investment),
                        Localized(.are_you_sure_you_want_to_cancel_investment),
                        [Localized(.yes)],
                        onSelected
                    )
                }
                investingTabView.onDidEnterAmount = { [weak self] (amount) in
                    let request = Event.EditAmount.Request(amount: amount)
                    self?.interactorDispatch?.sendRequest { businessLogic in
                        businessLogic.onEditAmount(request: request)
                    }
                }
                contentView = investingTabView
            } else if let tabContent = tabContent as? SaleDetails.DescriptionTab.ViewModel {
                let descriptionTabView = SaleDetails.DescriptionTab.View()
                tabContent.setup(tab: descriptionTabView)
                
                descriptionTabView.onDidSelectMoreInfoButton = { [weak self] (identifier) in
                    let request = Event.DidSelectMoreInfoButton.Request()
                    self?.interactorDispatch?.sendRequest { businessLogic in
                        businessLogic.onDidSelectMoreInfoButton(request: request)
                    }
                }
                contentView = descriptionTabView
            } else if let tabContent = tabContent as? SaleDetails.ChartTab.ViewModel {
                let chartTabView = SaleDetails.ChartTab.View()
                tabContent.setup(tab: chartTabView)
                
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
                contentView = chartTabView
            } else if let tabContent = tabContent as? SaleDetails.OverviewTab.ViewModel {
                let overviewTabView = SaleDetails.OverviewTab.View()
                tabContent.setup(tab: overviewTabView)
                contentView = overviewTabView
            } else if let tabContent = tabContent as? SaleDetails.EmptyContent.ViewModel {
                let emptyTabView = SaleDetails.EmptyContent.View()
                tabContent.setup(emptyTabView)
                contentView = emptyTabView
            } else {
                contentView = UIView()
            }
            
            self.contentView = contentView
            self.containerView.subviews.forEach { (view) in
                view.removeFromSuperview()
            }
            
            self.containerView.addSubview(contentView)
            contentView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
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
        self.updateInvestingTab(viewModel.updatedTab)
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
    
    func displayDidSelectMoreInfoButton(viewModel: SaleDetails.Event.DidSelectMoreInfoButton.ViewModel) {
        let saleInfoModel = SaleDetails.Model.SaleInfoModel(
            saleId: viewModel.saleId,
            asset: viewModel.asset
        )
        self.routing?.onSaleInfoAction(saleInfoModel)
    }
    
    func displaySelectChartPeriod(viewModel: Event.SelectChartPeriod.ViewModel) {
        guard let contentView = self.contentView,
            let chartView = contentView as? SaleDetails.ChartTab.View else {
                return
        }
        viewModel.viewModel.setup(tab: chartView)
    }
    
    func displaySelectChartEntry(viewModel: Event.SelectChartEntry.ViewModel) {
        guard let contentView = self.contentView,
            let chartView = contentView as? SaleDetails.ChartTab.View else {
                return
        }
        viewModel.viewModel.setup(tab: chartView)
    }
    
    func displayTabWasSelected(viewModel: Event.TabWasSelected.ViewModel) {
        self.setContentView(tabContent: viewModel.tabContent)
    }
}
