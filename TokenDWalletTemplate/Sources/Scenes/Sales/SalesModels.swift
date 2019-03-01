import UIKit
import RxSwift

enum Sales {
    
    // MARK: - Typealiases
    
    typealias CellIdentifier = String
    
    // MARK: -
    
    enum Model {}
    enum Event {}
}

// MARK: - Models

extension Sales.Model {
    struct SectionModel {
        let sales: [SaleModel]
    }
    
    struct SaleModel {
        let imageURL: URL?
        let name: String
        let description: String
        let asset: String
        
        let investmentAsset: String
        let investmentAmount: Decimal
        let investmentPercentage: Float
        let investorsCount: Int
        
        let startDate: Date
        let endDate: Date
        
        let saleIdentifier: String
    }
    
    struct SectionViewModel {
        let cells: [CellViewAnyModel]
    }
    
}

// MARK: - Events

extension Sales.Event {
    enum ViewDidLoad {
        struct Request {}
    }
    
    enum SectionsUpdated {
        struct Response {
            let sections: [Sales.Model.SectionModel]
        }
        struct ViewModel {
            let sections: [Sales.Model.SectionViewModel]
        }
    }
    
    enum LoadingStatusDidChange {
        typealias Response = Sales.SectionsProvider.LoadingStatus
        typealias ViewModel = Sales.SectionsProvider.LoadingStatus
    }

    enum EmptyResult {
        typealias Response = Sales.EmptyView.Model
        typealias ViewModel = Sales.EmptyView.ViewModel
    }

    enum DidInitiateRefresh {
        struct Request {}
    }
    
    enum DidInitiateLoadMore {
        struct Request {}
    }
    
    enum LoadingError {
        struct Response {
            let error: Swift.Error
        }
        
        struct ViewModel {
            let errorMessage: String
        }
    }
}

// MARK: -

extension Sales.Model.SaleModel {
    enum ImageState {
        case empty
        case loaded(UIImage)
        case loading
    }
}
