import UIKit

public protocol PollsDisplayLogic: class {
    typealias Event = Polls.Event
    
    func displaySceneUpdated(viewModel: Event.SceneUpdated.ViewModel)
    func displaySelectBalance(viewModel: Event.SelectBalance.ViewModel)
}

extension Polls {
    public typealias DisplayLogic = PollsDisplayLogic
    
    @objc(PollsViewController)
    public class ViewController: UIViewController {
        
        public typealias Event = Polls.Event
        public typealias Model = Polls.Model
        
        // MARK: - Private properties
        
        private let navigationTitleView: NavigationTitleView = NavigationTitleView()
        private let tableView: UITableView = UITableView(frame: .zero, style: .grouped)
        
        private var polls: [PollCell.ViewModel] = [] {
            didSet {
                self.tableView.reloadData()
            }
        }
        
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
            self.setupNavigationTitleView()
            self.setupTableView()
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
        
        private func setupNavigationTitleView() {
            self.navigationTitleView.onPickerSelected = { [weak self] in
                let request = Event.SelectBalance.Request()
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onSelectBalance(request: request)
                })
            }
            self.navigationItem.titleView = self.navigationTitleView
        }
        
        private func setupTableView() {
            self.tableView.backgroundColor = Theme.Colors.containerBackgroundColor
            self.tableView.register(classes: [
                PollCell.ViewModel.self
                ]
            )
            self.tableView.delegate = self
            self.tableView.dataSource = self
            self.tableView.separatorStyle = .none
        }
        
        private func setupLayout() {
            self.view.addSubview(self.tableView)
            self.tableView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }
}

extension Polls.ViewController: Polls.DisplayLogic {
    
    public func displaySceneUpdated(viewModel: Event.SceneUpdated.ViewModel) {
        self.polls = viewModel.polls
        self.navigationTitleView.setAsset(asset: viewModel.asset)
    }
    
    public func displaySelectBalance(viewModel: Event.SelectBalance.ViewModel) {
        let onSelected: (String) -> Void = { [weak self] (balanceId) in
            let request = Event.BalanceSelected.Request(balanceId: balanceId)
            self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                businessLogic.onBalanceSelected(request: request)
            })
        }
        self.routing?.onPresentPicker(
            viewModel.assets,
            onSelected
        )
    }
}

extension Polls.ViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = self.polls[indexPath.row]
        self.routing?.onPollSelected()
    }
}

extension Polls.ViewController: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.polls.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = self.polls[indexPath.section]
        let cell = tableView.dequeueReusableCell(with: model, for: indexPath)
        return cell
    }
}
