import UIKit

public enum AssetPicker {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension AssetPicker.Model {
    
    struct SceneModel {
        var assets: [Asset]
        var filterPrefix: String?
    }
    
    public struct Asset {
        let code: String
        let balance: Balance
    }
    
    public struct Balance {
        let amount: Decimal
        let balanceId: String
    }
}

// MARK: - Events

extension AssetPicker.Event {
    public typealias Model = AssetPicker.Model
    
    // MARK: -
    
    public enum ViewDidLoad {
        public struct Request {}
    }
    
    public enum AssetsUpdated {
        public enum Response {
            case assets([Model.Asset])
            case empty
        }
        
        public enum ViewModel {
            case assets([AssetPicker.AssetCell.ViewModel])
            case empty
        }
    }
    
    public enum DidFilter {
        public struct Request {
            let filterPrefix: String
        }
    }
}
