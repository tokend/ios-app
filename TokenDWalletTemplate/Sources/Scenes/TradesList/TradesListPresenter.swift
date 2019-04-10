import UIKit

public protocol TradesListPresentationLogic {
    typealias Event = TradesList.Event
    
    func presentLoadingStatus(response: Event.LoadingStatus.Response)
    func presentError(response: Event.Error.Response)
    func presentQuoteAssetsUpdate(response: Event.QuoteAssetsUpdate.Response)
    func presentAssetPairsListUpdate(response: Event.AssetPairsListUpdate.Response)
}

extension TradesList {
    public typealias PresentationLogic = TradesListPresentationLogic
    
    @objc(TradesListPresenter)
    public class Presenter: NSObject {
        
        public typealias Event = TradesList.Event
        public typealias Model = TradesList.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        
        // MARK: -
        
        public init(presenterDispatch: PresenterDispatch) {
            self.presenterDispatch = presenterDispatch
        }
        
        // MARK: - Private
        
        private func getAssetPairViewModels(_ assetPairs: [Model.AssetPair]) -> [Model.AssetPairViewModel] {
            return assetPairs.map({ (assetPair) -> Model.AssetPairViewModel in
                let defaultLogoLetter: Character = " "
                let logoLetter = String(assetPair.baseAsset.first ?? defaultLogoLetter)
                let logoColoring = UIColor.blue
                
                let title = NSMutableAttributedString(
                    string: assetPair.baseAsset,
                    attributes: [:]
                )
                
                let subTitle = "\(assetPair.currentPrice)"
                
                return Model.AssetPairViewModel(
                    logoLetter: logoLetter,
                    logoColoring: logoColoring,
                    title: title,
                    subTitle: subTitle,
                    id: assetPair.id
                )
            })
        }
    }
}

extension TradesList.Presenter: TradesList.PresentationLogic {
    
    public func presentLoadingStatus(response: Event.LoadingStatus.Response) {
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayLoadingStatus(viewModel: response)
        }
    }
    
    public func presentError(response: Event.Error.Response) {
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayError(viewModel: .init(error: response.error.localizedDescription))
        }
    }
    
    public func presentQuoteAssetsUpdate(response: Event.QuoteAssetsUpdate.Response) {
        let assetPairs = self.getAssetPairViewModels(response.assetPairs)
        
        let viewModel = Event.QuoteAssetsUpdate.ViewModel(
            quoteAsset: response.quoteAsset,
            selectedQuoteAssetIndex: response.selectedQuoteAssetIndex,
            assetPairs: assetPairs
        )
        
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayQuoteAssetsUpdate(viewModel: viewModel)
        }
    }
    
    public func presentAssetPairsListUpdate(response: Event.AssetPairsListUpdate.Response) {
        let assetPairs = self.getAssetPairViewModels(response.assetPairs)
        
        let viewModel = Event.AssetPairsListUpdate.ViewModel(
            assetPairs: assetPairs
        )
        
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayAssetPairsListUpdate(viewModel: viewModel)
        }
    }
}
