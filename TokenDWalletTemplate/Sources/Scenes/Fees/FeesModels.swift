import UIKit

enum Fees {
    
    // MARK: - Typealiases
    
    typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?

    // MARK: -
    
    enum CellIdentifier: String {
        case subtype
        case fixed
        case percent
        case lowerBound
        case upperBound
    }
    
    enum Model {}
    enum Event {}
}

// MARK: - Models

extension Fees.Model {
    
    struct SceneModel {
        var fees: [(asset: String, fees: [FeeModel])]
        var selectedAsset: String?
    }
    
    struct FeeModel {
        let asset: String
        let feeAsset: String
        let feeType: FeeType?
        let subtype: Subtype?
        let fixed: Decimal
        let percent: Decimal
        let lowerBound: Decimal
        let upperBound: Decimal
    }
    
    enum FeeType: Int32 {
        case paymentFee = 0
        case offerFee = 1
        case withdrawalFee = 2
        case investFee = 4
    }
    
    enum Subtype: Int32 {
        case incomingOutgoing = 0
        case outgoing = 1
        case incoming = 2
    }
    
    struct FeeViewModel {
        let feeType: String
        let subtype: String
        let fixed: String
        let percent: String
        let lowerBound: String
        let upperBound: String
    }
    
    struct SectionViewModel {
        let title: String
        let cells: [Fees.TitleValueViewModel]
    }
    
    enum LoadingStatus {
        case loaded
        case loading
    }
}

// MARK: - Events

extension Fees.Event {
    typealias Model = Fees.Model
    
    // MARK: -
    
    enum ViewDidLoad {
        struct Request {}
    }
    
    enum LoadingStatusDidChange {
        struct Response {
            let status: Model.LoadingStatus
        }
        
        typealias ViewModel = Response
    }
    
    enum Error {
        struct Response {
            let message: String
        }
        
        typealias ViewModel = Response
    }
    
    enum TabsDidUpdate {
        struct Response {
            let titles: [String]
            let fees: [Model.FeeModel]
            let selectedTabIndex: Int?
        }
        
        struct ViewModel {
            let titles: [String]
            let sections: [Model.SectionViewModel]
            let selectedTabIndex: Int?
        }
    }
    
    enum TabWasSelected {
        struct Request {
            let selectedAssetIndex: Int
        }
        
        struct Response {
            let models: [Model.FeeModel]
        }
        
        struct ViewModel {
            let sections: [Model.SectionViewModel]
        }
    }
}
