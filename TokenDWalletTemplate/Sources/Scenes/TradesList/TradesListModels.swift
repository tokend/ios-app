import UIKit

public enum TradesList {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    public typealias Asset = String
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension TradesList.Model {
    
    public typealias Asset = TradesList.Asset
    
    public struct SceneModel {
        
        public var quoteAssets: [Asset]
        public var selectedQuoteAsset: Asset?
        public var assetPairs: [AssetPair]
        public var selectedAssetPairs: [AssetPair]
        
        public init(
            quoteAssets: [Asset],
            selectedQuoteAsset: Asset?,
            assetPairs: [AssetPair],
            selectedAssetPairs: [AssetPair]
            ) {
            
            self.quoteAssets = quoteAssets
            self.selectedQuoteAsset = selectedQuoteAsset
            self.assetPairs = assetPairs
            self.selectedAssetPairs = selectedAssetPairs
        }
        
        public init() {
            self.quoteAssets = []
            self.selectedQuoteAsset = nil
            self.assetPairs = []
            self.selectedAssetPairs = []
        }
    }
    
    public struct AssetPair {
        
        public let baseAsset: String
        public let quoteAsset: String
        public let currentPrice: Decimal
        
        public init(
            baseAsset: String,
            quoteAsset: String,
            currentPrice: Decimal
            ) {
            
            self.baseAsset = baseAsset
            self.quoteAsset = quoteAsset
            self.currentPrice = currentPrice
        }
    }
    
    public struct AssetPairViewModel {
        
        public let logoLetter: String
        public let logoColoring: UIColor
        public let title: NSAttributedString
        public let subTitle: String
        public let baseAsset: String
        public let quoteAsset: String
        public let currentPrice: Decimal
        
        public init(
            logoLetter: String,
            logoColoring: UIColor,
            title: NSAttributedString,
            subTitle: String,
            baseAsset: String,
            quoteAsset: String,
            currentPrice: Decimal
            ) {
            
            self.logoLetter = logoLetter
            self.logoColoring = logoColoring
            self.title = title
            self.subTitle = subTitle
            self.baseAsset = baseAsset
            self.quoteAsset = quoteAsset
            self.currentPrice = currentPrice
        }
    }
}

// MARK: - Events

extension TradesList.Event {
    public typealias Model = TradesList.Model
    
    // MARK: -
    
    public enum ViewDidLoad {
        public struct Request { public init() {} }
    }
    
    public enum LoadingStatus {
        public typealias Response = TradesList.AssetPairsFetcherProtocol.LoadingStatus
        public typealias ViewModel = Response
    }
    
    public enum PullToRefresh {
        public struct Request { public init() {} }
    }
    
    public enum Error {
        public struct Response {
            public let error: Swift.Error
            
            public init(error: Swift.Error) {
                self.error = error
            }
        }
        public struct ViewModel {
            public let error: String
            
            public init(error: String) {
                self.error = error
            }
        }
    }
    
    public enum QuoteAssetsUpdate {
        
        public struct Response {
            
            public let quoteAsset: [Model.Asset]
            public let selectedQuoteAssetIndex: Int?
            public let assetPairs: [Model.AssetPair]
            
            public init(
                quoteAsset: [Model.Asset],
                selectedQuoteAssetIndex: Int?,
                assetPairs: [Model.AssetPair]
                ) {
                
                self.quoteAsset = quoteAsset
                self.selectedQuoteAssetIndex = selectedQuoteAssetIndex
                self.assetPairs = assetPairs
            }
        }
        
        public struct ViewModel {
            
            public let quoteAsset: [Model.Asset]
            public let selectedQuoteAssetIndex: Int?
            public let assetPairs: [Model.AssetPairViewModel]
            
            public init(
                quoteAsset: [Model.Asset],
                selectedQuoteAssetIndex: Int?,
                assetPairs: [Model.AssetPairViewModel]
                ) {
                
                self.quoteAsset = quoteAsset
                self.selectedQuoteAssetIndex = selectedQuoteAssetIndex
                self.assetPairs = assetPairs
            }
        }
    }
    
    public enum AssetPairsListUpdate {
        public struct Response {
            public let assetPairs: [Model.AssetPair]
            
            public init(assetPairs: [Model.AssetPair]) {
                self.assetPairs = assetPairs
            }
        }
        public struct ViewModel {
            public let assetPairs: [Model.AssetPairViewModel]
            
            public init(assetPairs: [Model.AssetPairViewModel]) {
                self.assetPairs = assetPairs
            }
        }
    }
    
    public enum QuoteAssetSelected {
        public struct Request {
            public let quoteAsset: Model.Asset
        }
    }
}

// MARK: -

extension TradesList.Model.AssetPair: Equatable {
    
    public static func ==(left: TradesList.Model.AssetPair, right: TradesList.Model.AssetPair) -> Bool {
        return left.baseAsset == right.baseAsset
            && left.quoteAsset == right.quoteAsset
    }
}
