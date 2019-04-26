import Foundation
import RxCocoa
import RxSwift

public protocol TradesListBusinessLogic {
    typealias Event = TradesList.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onPullToRefresh(request: Event.PullToRefresh.Request)
    func onQuoteAssetSelected(request: Event.QuoteAssetSelected.Request)
}

extension TradesList {
    public typealias BusinessLogic = TradesListBusinessLogic
    
    @objc(TradesListInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = TradesList.Event
        public typealias Model = TradesList.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private let assetPairsFetcher: AssetPairsFetcherProtocol
        
        private var sceneModel: Model.SceneModel
        
        private let disposeBag = DisposeBag()
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic,
            assetPairsFetcher: AssetPairsFetcherProtocol
            ) {
            
            self.presenter = presenter
            self.assetPairsFetcher = assetPairsFetcher
            
            self.sceneModel = Model.SceneModel()
        }
        
        // MARK: - Private
        
        private func handleAssetPairs(_ assetPairs: [Model.AssetPair]) {
            let allAssetPairs = assetPairs
            
            var quoteAssets: [Model.Asset] = []
            for assetPair in allAssetPairs where !quoteAssets.contains(assetPair.quoteAsset) {
                quoteAssets.append(assetPair.quoteAsset)
            }
            
            let selectedQuoteAsset: Model.Asset?
            if let previouslySelectedAsset = self.sceneModel.selectedQuoteAsset,
                quoteAssets.contains(previouslySelectedAsset) {
                selectedQuoteAsset = previouslySelectedAsset
            } else if let firstQuoteAsset = quoteAssets.first {
                selectedQuoteAsset = firstQuoteAsset
            } else {
                selectedQuoteAsset = nil
            }
            
            let selectedQuoteAssetIndex: Int?
            if let selected = selectedQuoteAsset, let index = quoteAssets.index(of: selected) {
                selectedQuoteAssetIndex = index
            } else {
                selectedQuoteAssetIndex = nil
            }
            
            let selectedAssetPairs = self.filterAssetPairs(selectedQuoteAsset, allAssetPairs: allAssetPairs)
            
            self.sceneModel.assetPairs = allAssetPairs
            self.sceneModel.quoteAssets = quoteAssets
            self.sceneModel.selectedQuoteAsset = selectedQuoteAsset
            self.sceneModel.selectedAssetPairs = selectedAssetPairs
            
            let response = Event.QuoteAssetsUpdate.Response(
                quoteAsset: quoteAssets,
                selectedQuoteAssetIndex: selectedQuoteAssetIndex,
                assetPairs: selectedAssetPairs
            )
            self.presenter.presentQuoteAssetsUpdate(response: response)
        }
        
        private func handleSelectedQuoteAsset(_ selectedQuoteAsset: Model.Asset) {
            let allAssetPairs = self.sceneModel.assetPairs
            
            let selectedAssetPairs = self.filterAssetPairs(selectedQuoteAsset, allAssetPairs: allAssetPairs)
            
            self.sceneModel.selectedQuoteAsset = selectedQuoteAsset
            self.sceneModel.selectedAssetPairs = selectedAssetPairs
            
            let response = Event.AssetPairsListUpdate.Response(
                assetPairs: selectedAssetPairs
            )
            self.presenter.presentAssetPairsListUpdate(response: response)
        }
        
        private func filterAssetPairs(
            _ quoteAsset: Asset?,
            allAssetPairs: [Model.AssetPair]
            ) -> [Model.AssetPair] {
            
            guard let quoteAsset = quoteAsset else {
                return []
            }
            
            let filteredAssetPairs = allAssetPairs.filter { (assetPair) -> Bool in
                return assetPair.quoteAsset == quoteAsset
            }
            
            return filteredAssetPairs
        }
    }
}

extension TradesList.Interactor: TradesList.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        self.assetPairsFetcher.observeAssetPairs()
            .subscribe(onNext: { [weak self] (assetPairs) in
                self?.handleAssetPairs(assetPairs)
            })
            .disposed(by: self.disposeBag)
        
        self.assetPairsFetcher.observeAssetPairsLoadingStatus()
            .subscribe(onNext: { [weak self] (loadingStatus) in
                self?.presenter.presentLoadingStatus(response: loadingStatus)
            })
            .disposed(by: self.disposeBag)
        
        self.assetPairsFetcher.observeAssetPairsError()
            .subscribe(onNext: { [weak self] (error) in
                self?.presenter.presentError(response: .init(error: error))
            })
            .disposed(by: self.disposeBag)
        
        self.assetPairsFetcher.updateAssetPairs()
    }
    
    public func onPullToRefresh(request: Event.PullToRefresh.Request) {
        self.assetPairsFetcher.updateAssetPairs()
    }
    
    public func onQuoteAssetSelected(request: Event.QuoteAssetSelected.Request) {
        self.handleSelectedQuoteAsset(request.quoteAsset)
    }
}
