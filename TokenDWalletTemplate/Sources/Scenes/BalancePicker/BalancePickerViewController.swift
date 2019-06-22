import UIKit

public protocol BalancePickerDisplayLogic: class {
    typealias Event = BalancePicker.Event
    
    func displayBalancesUpdated(viewModel: Event.BalancesUpdated.ViewModel)
}

extension BalancePicker {
    public typealias DisplayLogic = BalancePickerDisplayLogic
    
    @objc(BalancesPickerViewController)
    public class ViewController: UIViewController {
        
        public typealias Event = BalancePicker.Event
        public typealias Model = BalancePicker.Model
        
        // MARK: - Private properties
        
        private let searchController: UISearchController = UISearchController(searchResultsController: nil)
        private let tableView: UITableView = UITableView(frame: .zero, style: .grouped)
        private let emptyView: EmptyView = EmptyView()
        private var balances: [BalanceCell.ViewModel] = []
        
        private let bottomInset: CGFloat = 32.0
        
        // MARK: -
        
        deinit {
            self.onDeinit?(self)
        }
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        private var onDeinit: DeinitCompletion = nil
        
        public func inject(
            interactorDispatch: InteractorDispatch?,
            routing: Routing?,
            onDeinit: DeinitCompletion = nil
            ) {
            
            self.interactorDispatch = interactorDispatch
            self.routing = routing
            self.onDeinit = onDeinit
        }
        
        // MARK: - Overridden
        
        public override func viewDidLoad() {
            super.viewDidLoad()
            
            self.setupView()
            self.setupSearchController()
            self.setupTableView()
            self.setupEmptyView()
            self.setupLayout()
            
            self.addKeyboardObserver()
            
            let request = Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        // MARK: - Private
        
        private func addKeyboardObserver() {
            let keyboardObserver = KeyboardObserver(self) { [weak self] (attributes) in
                self?.setBottomInsetWithKeyboardAttributes(attributes)
            }
            KeyboardController.shared.add(observer: keyboardObserver)
        }
        
        private func setBottomInsetWithKeyboardAttributes(
            _ attributes: KeyboardAttributes?
            ) {
            
            let keyboardHeightInTableView: CGFloat = attributes?.heightInContainerView(
                self.view,
                view: self.tableView
                ) ?? 0
            var bottomInset: CGFloat = self.bottomInset + keyboardHeightInTableView
            if attributes?.showingIn(view: self.view) != true {
                if #available(iOS 11, *) {
                    bottomInset += self.view.safeAreaInsets.bottom
                } else {
                    bottomInset += self.bottomLayoutGuide.length
                }
            }
            self.tableView.contentInset.bottom = bottomInset
        }
        
        private func setupView() {
            self.extendedLayoutIncludesOpaqueBars = true
            
            if #available(iOS 11, *) {
                self.navigationItem.searchController = self.searchController
                self.navigationItem.hidesSearchBarWhenScrolling = false
                self.definesPresentationContext = true
            }
        }
        
        private func setupSearchController() {
            self.searchController.searchBar.placeholder = Localized(.search)
            self.searchController.searchResultsUpdater = self
            self.searchController.obscuresBackgroundDuringPresentation = false
            self.searchController.dimsBackgroundDuringPresentation = false
            self.searchController.hidesNavigationBarDuringPresentation = false
            
            if #available(iOS 11, *) {
                let searchBar = self.searchController.searchBar
                searchBar.tintColor = Theme.Colors.contentBackgroundColor
                searchBar.barTintColor = Theme.Colors.contentBackgroundColor
                
                if let textField = searchBar.value(forKey: "searchField") as? UITextField {
                    if let backgroundView = textField.subviews.first {
                        backgroundView.backgroundColor = Theme.Colors.contentBackgroundColor
                        backgroundView.layer.cornerRadius = 10
                        backgroundView.clipsToBounds = true
                    }
                }
            }
        }
        
        private func setupTableView() {
            self.tableView.backgroundColor = Theme.Colors.containerBackgroundColor
            self.tableView.register(classes: [
                BalanceCell.ViewModel.self
                ]
            )
            self.tableView.delegate = self
            self.tableView.dataSource = self
            self.tableView.keyboardDismissMode = .onDrag
            
            if #available(iOS 11, *) { } else {
                self.tableView.tableHeaderView = self.searchController.searchBar
            }
        }
        
        private func setupEmptyView() {
            self.emptyView.isHidden = true
        }
        
        private func setupLayout() {
            self.view.addSubview(self.tableView)
            self.view.addSubview(self.emptyView)
            
            self.tableView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            
            self.emptyView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }
}

extension BalancePicker.ViewController: BalancePicker.DisplayLogic {
    
    public func displayBalancesUpdated(viewModel: Event.BalancesUpdated.ViewModel) {
        switch viewModel {
            
        case .empty:
            self.emptyView.isHidden = false
            
        case .balances(let balances):
            self.emptyView.isHidden = true
            self.balances = balances
            self.tableView.reloadData()
        }
    }
}

extension BalancePicker.ViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let balance = self.balances[indexPath.row]
        if self.searchController.isActive {
            self.searchController.dismiss(animated: true, completion: nil)
        }
        self.dismiss(
            animated: true,
            completion: { [weak self] in
                self?.routing?.onBalancePicked(balance.balanceId)
            })
    }
}

extension BalancePicker.ViewController: UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.balances.count
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = self.balances[indexPath.row]
        let cell = tableView.dequeueReusableCell(with: model, for: indexPath)
        
        return cell
    }
}

extension BalancePicker.ViewController: UISearchResultsUpdating {
    
    public func updateSearchResults(for searchController: UISearchController) {
        let filter = searchController.searchBar.text
        
        self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
            let request = Event.DidFilter.Request(filter: filter)
            businessLogic.onDidFilter(request: request)
        })
    }
}
