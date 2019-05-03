import UIKit

public enum Limits {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension Limits.Model {
    
    public typealias Asset = String
    
    public struct SceneModel {
        
        public var limits: [Asset: [LimitsModel]] = [:]
        public var selectedAsset: Asset?
        
        public init() {
            
        }
    }
    
    public struct LimitsModel {
        
        public let operation: String
        public let limits: [LimitModel]
        
        public init(
            operation: String,
            limits: [LimitModel]
            ) {
            
            self.operation = operation
            self.limits = limits
        }
    }
    
    public struct LimitModel {
        
        public let dailyOut: Decimal
        public let weeklyOut: Decimal
        public let monthlyOut: Decimal
        public let annualOut: Decimal
        
        public init(
            dailyOut: Decimal,
            weeklyOut: Decimal,
            monthlyOut: Decimal,
            annualOut: Decimal
            ) {
            
            self.dailyOut = dailyOut
            self.weeklyOut = weeklyOut
            self.monthlyOut = monthlyOut
            self.annualOut = annualOut
        }
    }
    
    public struct LimitsViewModel {
        
        public let title: String
        public let limits: [LimitViewModel]
        
        public init(
            title: String,
            limits: [LimitViewModel]
            ) {
            
            self.title = title
            self.limits = limits
        }
    }
    
    public struct LimitViewModel {
        
        public let dailyOut: Decimal
        public let weeklyOut: Decimal
        public let monthlyOut: Decimal
        public let annualOut: Decimal
        
        public init(
            dailyOut: Decimal,
            weeklyOut: Decimal,
            monthlyOut: Decimal,
            annualOut: Decimal
            ) {
            
            self.dailyOut = dailyOut
            self.weeklyOut = weeklyOut
            self.monthlyOut = monthlyOut
            self.annualOut = annualOut
        }
    }
}

// MARK: - Events

extension Limits.Event {
    
    public typealias Model = Limits.Model
    
    // MARK: -
    
    public enum ViewDidLoad {
        
        public struct Request { public init() {} }
    }
    
    public enum LoadingStatus {
        
        public struct Response {
            
            public let isLoading: Bool
            
            public init(isLoading: Bool) {
                self.isLoading = isLoading
            }
        }
        
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
    
    public enum LimitsUpdated {
        
        public struct Response {
            
            public let assets: [Model.Asset]
            public let selectedAssetIndex: Int?
            public let limits: [Model.LimitsModel]
            
            public init(
                assets: [Model.Asset],
                selectedAssetIndex: Int?,
                limits: [Model.LimitsModel]
                ) {
                
                self.assets = assets
                self.selectedAssetIndex = selectedAssetIndex
                self.limits = limits
            }
        }
        
        public struct ViewModel {
            
            public let assets: [Model.Asset]
            public let selectedAssetIndex: Int?
            public let limits: [Model.LimitsViewModel]
            
            public init(
                assets: [Model.Asset],
                selectedAssetIndex: Int?,
                limits: [Model.LimitsViewModel]
                ) {
                
                self.assets = assets
                self.selectedAssetIndex = selectedAssetIndex
                self.limits = limits
            }
        }
    }
    
    public enum AssetSelected {
        
        public struct Request {
            
            public let asset: Model.Asset
            
            public init(asset: Model.Asset) {
                self.asset = asset
            }
        }
    }
}
