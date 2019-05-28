import UIKit
import RxCocoa
import RxSwift

public protocol TradesListDisplayLogic: class {
    typealias Event = TradesList.Event
    
    func displayLoadingStatus(viewModel: Event.LoadingStatus.ViewModel)
    func displayError(viewModel: Event.Error.ViewModel)
    func displayQuoteAssetsUpdate(viewModel: Event.QuoteAssetsUpdate.ViewModel)
    func displayAssetPairsListUpdate(viewModel: Event.AssetPairsListUpdate.ViewModel)
}

extension TradesList {
    public typealias DisplayLogic = TradesListDisplayLogic
    
    @objc(TradesListViewController)
    public class ViewController: UIViewController {
        
        public typealias Event = TradesList.Event
        public typealias Model = TradesList.Model
        
        // MARK: - Private properties
        
        private let pairPicker: HorizontalPicker = HorizontalPicker(frame: CGRect.zero)
        private let tableView: DynamicTableView = DynamicTableView()
        
        private var assetPairs: [Model.AssetPairViewModel] = [] {
            didSet {
                self.tableView.reloadData()
            }
        }
        
        private let disposeBag = DisposeBag()
        
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
            
            self.setupPendingOffersButton()
            self.setupPairPicker()
            self.setupTableView()
            self.setupRefreshControl()
            self.setupLayout()
            
            let request = Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        // MARK: - Private
        
        private func setupPendingOffersButton() {
            let button = UIBarButtonItem(
                image: Assets.pendingIcon.image,
                style: .plain,
                target: nil,
                action: nil
            )
            
            button.rx
                .tap
                .asDriver()
                .drive(onNext: { [weak self] in
                    self?.routing?.onSelectPendingOffers()
                })
                .disposed(by: self.disposeBag)
            
            self.navigationItem.rightBarButtonItem = button
        }
        
        private func setupPairPicker() {
            self.pairPicker.backgroundColor = Theme.Colors.mainColor
            self.pairPicker.tintColor = Theme.Colors.darkAccentColor
        }
        
        private func setupTableView() {
            self.tableView.backgroundColor = Theme.Colors.containerBackgroundColor
            self.tableView.dataSource = self
        }
        
        private func setupRefreshControl() {
            self.tableView.pullToRefreshEnabled = true
            self.tableView.onPullToRefresh = { [weak self] in
                let request = Event.PullToRefresh.Request()
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onPullToRefresh(request: request)
                })
            }
        }
        
        private func setupLayout() {
            self.view.addSubview(self.pairPicker)
            self.view.addSubview(self.tableView)
            
            self.pairPicker.snp.makeConstraints { (make) in
                make.leading.trailing.top.equalToSuperview()
            }
            
            self.tableView.snp.makeConstraints { (make) in
                make.top.equalTo(self.pairPicker.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }
        }
    }
}

extension TradesList.ViewController: DynamicTableViewDataSourceDelegate {
    
    public func numberOfSections() -> Int {
        return 1
    }
    
    public func numberOfRowsIn(section: Int) -> Int {
        return self.assetPairs.count
    }
    
    public func contentAt(indexPath: IndexPath, currentContent: UIView?) -> UIView? {
        let assetPairListView: TradesList.AssetPairListView
        if let prevView = currentContent as? TradesList.AssetPairListView {
            assetPairListView = prevView
        } else {
            assetPairListView = TradesList.AssetPairListView()
        }
        
        let assetPair = self.assetPairs[indexPath.row]
        
        assetPairListView.logoLetter = assetPair.logoLetter
        assetPairListView.logoColoring = assetPair.logoColoring
        assetPairListView.title = assetPair.title
        assetPairListView.subTitle = assetPair.subTitle
        
        return assetPairListView
    }
    
    public func onSelectRowAt(indexPath: IndexPath) {
        let assetPair = self.assetPairs[indexPath.row]
        
        self.routing?.onSelectAssetPair(
            assetPair.baseAsset,
            assetPair.quoteAsset,
            assetPair.currentPrice
        )
    }
    
    public func showsCellSeparator() -> Bool {
        return false
    }
}

extension TradesList.ViewController: TradesList.DisplayLogic {
    
    public func displayLoadingStatus(viewModel: Event.LoadingStatus.ViewModel) {
        switch viewModel {
            
        case .loaded:
            self.tableView.endRefreshing()
            
        case .loading:
            self.tableView.beginRefreshing()
        }
    }
    
    public func displayError(viewModel: Event.Error.ViewModel) {
        self.routing?.onShowError(viewModel.error)
    }
    
    public func displayQuoteAssetsUpdate(viewModel: Event.QuoteAssetsUpdate.ViewModel) {
        self.pairPicker.items = viewModel.quoteAsset.map({ (asset) -> HorizontalPicker.Item in
            return HorizontalPicker.Item(
                title: asset,
                enabled: true,
                onSelect: { [weak self] in
                    let request = Event.QuoteAssetSelected.Request(quoteAsset: asset)
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onQuoteAssetSelected(request: request)
                    })
            })
        })
        self.pairPicker.setSelectedItemAtIndex(viewModel.selectedQuoteAssetIndex ?? 0, animated: false)
        
        self.assetPairs = viewModel.assetPairs
    }
    
    public func displayAssetPairsListUpdate(viewModel: Event.AssetPairsListUpdate.ViewModel) {
        self.assetPairs = viewModel.assetPairs
    }
}
