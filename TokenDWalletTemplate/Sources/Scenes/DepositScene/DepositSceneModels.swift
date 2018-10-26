import UIKit

enum DepositScene {
    
    // MARK: - Typealiases
    
    typealias AssetID = String
    
    // MARK: -
    
    enum Model {}
    enum Event {}
}

// MARK: - Models

extension DepositScene.Model {
    struct SceneModel {
        var selectedAssetId: DepositScene.AssetID
        var assets: [Asset]
        var qrCodeSize: CGSize
    }
    
    struct Asset {
        let id: DepositScene.AssetID
        let address: String?
        let asset: String
        let expirationDate: Date?
        let isRenewable: Bool
        let isRenewing: Bool
        let externalSystemType: Int32
    }
    
    enum AssetsViewModel {
        case assets([AssetViewModel])
        case empty(String)
    }
    
    struct AssetViewModel {
        let id: DepositScene.AssetID
        let asset: String
    }
}

// MARK: - Events

extension DepositScene.Event {
    typealias Model = DepositScene.Model
    
    // MARK: -
    
    enum ViewDidLoadSync {
        struct Request {}
        struct Response {
            let assets: [Model.Asset]
            let selectedAssetIndex: Int?
        }
        struct ViewModel {
            let assets: Model.AssetsViewModel
            let selectedAssetIndex: Int?
        }
    }
    
    enum ViewDidLoad {
        struct Request {}
    }
    
    enum DidInitiateRefresh {
        struct Request {}
    }
    
    enum Loading {
        struct Response {
            let status: DepositSceneAssetsFetcherLoadingStatus
        }
        
        struct ViewModel {
            let status: DepositSceneAssetsFetcherLoadingStatus
        }
    }
    
    enum Error {
        struct Response {
            let error: Swift.Error
        }
        
        struct ViewModel {
            let message: String
        }
    }
    
    enum ViewDidLayoutSubviews {
        struct Request {
            let qrCodeSize: CGSize
        }
    }
    
    enum QRDidChange {
        struct Response {
            let data: String?
            let size: CGSize
        }
        struct ViewModel {
            let qrCode: UIImage?
        }
    }
    
    enum AssetDidChange {
        enum RenewStatus {
            case renewable
            case renewing
            case notRenewable
        }
        struct Response {
            let asset: Model.Asset?
            let renewStatus: RenewStatus
            let canShare: Bool
        }
        enum ViewModel {
            case empty(hint: String)
            case withoutAddress(Data)
            case withAddress(Data)
            
            struct Data {
                let address: String?
                let hint: String
                let renewStatus: RenewStatus
                let canShare: Bool
            }
        }
    }
    
    enum AssetsDidChange {
        struct Response {
            let assets: [Model.Asset]
        }
        typealias ViewModel = Model.AssetsViewModel
    }
    
    enum DidSelectAsset {
        struct Request {
            let id: DepositScene.AssetID
        }
    }
    
    enum SelectAsset {
        struct Response {
            let index: Int?
        }
        struct ViewModel {
            let index: Int?
        }
    }
    
    enum RenewAddress {
        struct Request {}
    }
    
    enum GetAddress {
        struct Request {}
    }
    
    enum Share {
        struct Request {}
        struct Response {
            let items: [Any]
        }
        struct ViewModel {
            let items: [Any]
        }
    }
}
