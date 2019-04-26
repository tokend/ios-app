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
    
    enum Model {
        struct FeeModel: Equatable {
            let asset: String
            let feeAsset: String
            let feeType: FeeType?
            let subtype: Subtype?
            let fixed: Decimal
            let percent: Decimal
            let lowerBound: Decimal
            let upperBound: Decimal
        }
    }
    enum Event {}
}

// MARK: - Models

extension Fees.Model {
    
    struct SceneModel {
        var fees: [(asset: String, fees: [FeeModel])]
        var selectedAsset: String?
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

extension Fees.Model.FeeModel: Comparable {
    
    static func < (left: Fees.Model.FeeModel, right: Fees.Model.FeeModel) -> Bool {
        guard let leftFeeType = left.feeType else {
            return right.feeType != nil
        }
        
        guard let rightFeeType = right.feeType else {
            return true
        }
        
        guard leftFeeType.rawValue == rightFeeType.rawValue else {
            return leftFeeType.rawValue < rightFeeType.rawValue
        }
        
        guard let leftFeeSubType = left.subtype else {
            return right.subtype != nil
        }
        
        guard let rightFeeSubType = right.subtype else {
            return true
        }
        
        guard leftFeeSubType.rawValue == rightFeeSubType.rawValue else {
            return leftFeeSubType.rawValue < rightFeeSubType.rawValue
        }
        
        return left.lowerBound < right.lowerBound
    }
}
