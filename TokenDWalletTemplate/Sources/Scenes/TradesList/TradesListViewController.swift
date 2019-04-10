import UIKit

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
        
        private let pairPicker: HorizontalPicker = HorizontalPicker()
        private let tableView: DynamicTableView = DynamicTableView()
        
        private var assetPairs: [Model.AssetPairViewModel] = []
        
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
            
            self.setupTableView()
            self.setupLayout()
            
            let request = Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        // MARK: - Private
        
        private func setupTableView() {
            self.tableView.dataSource = self
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
        assetPairListView.id = assetPair.id
        
        return assetPairListView
    }
    
    public func onSelectRowAt(indexPath: IndexPath) {
        
    }
}

extension TradesList.ViewController: TradesList.DisplayLogic {
    
    public func displayLoadingStatus(viewModel: Event.LoadingStatus.ViewModel) {
        
    }
    
    public func displayError(viewModel: Event.Error.ViewModel) {
        
    }
    
    public func displayQuoteAssetsUpdate(viewModel: Event.QuoteAssetsUpdate.ViewModel) {
        
    }
    
    public func displayAssetPairsListUpdate(viewModel: Event.AssetPairsListUpdate.ViewModel) {
        
    }
}
