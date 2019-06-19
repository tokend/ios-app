import UIKit

protocol FeesDisplayLogic: class {
    typealias Event = Fees.Event
    
    func displayLoadingStatusDidChange(viewModel: Event.LoadingStatusDidChange.ViewModel)
    func displayError(viewModel: Event.Error.ViewModel)
    func displayTabsDidUpdate(viewModel: Event.TabsDidUpdate.ViewModel)
    func displayTabWasSelected(viewModel: Event.TabWasSelected.ViewModel)
}

extension Fees {
    typealias DisplayLogic = FeesDisplayLogic
    
    class ViewController: UIViewController {
        
        typealias Event = Fees.Event
        typealias Model = Fees.Model
        
        // MARK: - Private properties
        
        private let tableView: UITableView = UITableView(frame: .zero, style: .grouped)
        private let horisontalPicker: HorizontalPicker = HorizontalPicker()
        private var cards: [Fees.CardView.CardViewModel] = []
        
        // MARK: -
        
        deinit {
            self.onDeinit?(self)
        }
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        private var onDeinit: DeinitCompletion = nil
        
        func inject(
            interactorDispatch: InteractorDispatch?,
            routing: Routing?,
            onDeinit: DeinitCompletion = nil
            ) {
            
            self.interactorDispatch = interactorDispatch
            self.routing = routing
            self.onDeinit = onDeinit
        }
        
        // MARK: - Overridden
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.setupView()
            self.setupHorizontalPicker()
            self.setupTableView()
            self.setupLayout()
            
            let request = Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupHorizontalPicker() {
            self.horisontalPicker.backgroundColor = Theme.Colors.mainColor
            self.horisontalPicker.tintColor = Theme.Colors.darkAccentColor
        }
        
        private func setupTableView() {
            self.tableView.backgroundColor = Theme.Colors.containerBackgroundColor
            self.tableView.register(classes: [
                Fees.CardView.CardViewModel.self
                ]
            )
            self.tableView.delegate = self
            self.tableView.dataSource = self
            self.tableView.separatorStyle = .none
            self.tableView.estimatedRowHeight = 150.0
            self.tableView.rowHeight = UITableView.automaticDimension
        }
        
        private func setupLayout() {
            self.view.addSubview(self.horisontalPicker)
            self.view.addSubview(self.tableView)
            
            self.horisontalPicker.snp.makeConstraints { (make) in
                make.trailing.leading.top.equalToSuperview()
            }
            
            self.tableView.snp.makeConstraints { (make) in
                make.leading.trailing.bottom.equalToSuperview()
                make.top.equalTo(self.horisontalPicker.snp.bottom)
            }
        }
        
        private func updateSelectedTabIfNeeded(index: Int?) {
            if let index = index {
                if index != self.horisontalPicker.selectedItemIndex {
                    self.horisontalPicker.setSelectedItemAtIndex(index, animated: false)
                }
            }
        }
    }
}

extension Fees.ViewController: Fees.DisplayLogic {
    
    func displayLoadingStatusDidChange(viewModel: Event.LoadingStatusDidChange.ViewModel) {
        switch viewModel.status {
            
        case .loaded:
            self.routing?.hideProgress()
            
        case .loading:
            self.routing?.showProgress()
        }
    }
    
    func displayError(viewModel: Event.Error.ViewModel) {
        self.routing?.showMessage(viewModel.message)
    }
    
    func displayTabsDidUpdate(viewModel: Event.TabsDidUpdate.ViewModel) {
        let items: [HorizontalPicker.Item]
        
        if viewModel.titles.isEmpty {
            let emptyItem = HorizontalPicker.Item(
                title: Localized(.no_fees_to_overview),
                enabled: true,
                onSelect: {}
            )
            items = [emptyItem]
        } else {
            items = viewModel.titles.enumerated().map { (index, title) -> HorizontalPicker.Item in
                return HorizontalPicker.Item(
                    title: title,
                    enabled: true,
                    onSelect: { [weak self] in
                        let request = Event.TabWasSelected.Request(selectedAssetIndex: index)
                        self?.interactorDispatch?.sendRequest(requestBlock: { (bussinesLogic) in
                            bussinesLogic.onTabWasSelected(request: request)
                        })
                })
            }
        }
        
        self.horisontalPicker.items = items
        self.updateSelectedTabIfNeeded(index: viewModel.selectedTabIndex)
        self.cards = viewModel.cards
        self.tableView.reloadData()
    }
    
    func displayTabWasSelected(viewModel: Event.TabWasSelected.ViewModel) {
        self.cards = viewModel.cards
        self.tableView.reloadData()
    }
}

extension Fees.ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = self.cards[indexPath.section]
        let cell = tableView.dequeueReusableCell(with: model, for: indexPath)
        
        model.setupAny(cell: cell)
        
        return cell
    }
}

extension Fees.ViewController: UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.cards.count
    }
}
