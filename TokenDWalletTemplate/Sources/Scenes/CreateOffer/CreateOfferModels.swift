import Foundation

enum CreateOffer {
    
    // MARK: - Typealiases
    
    // MARK: -
    
    enum Model {}
    enum Event {}
}

// MARK: - Models

extension CreateOffer.Model {
    struct Amount {
        let value: Decimal?
        let asset: String
    }
    
    struct FeeModel {
        let asset: String
        let fixed: Decimal
        let percent: Decimal
    }
    
    struct CreateOfferModel {
        let baseAsset: String
        let quoteAsset: String
        let isBuy: Bool
        let amount: Decimal
        let price: Decimal
        let fee: Decimal
    }
    
    struct Button {
        let title: String?
        let type: ButtonType
    }
    
    struct Field {
        var value: Decimal?
        let type: FieldType
    }
    
    class SceneModel {
        let baseAsset: String
        let quoteAsset: String
        var amount: Decimal?
        var price: Decimal?
        
        init(
            baseAsset: String,
            quoteAsset: String,
            amount: Decimal?,
            price: Decimal?
            ) {
            
            self.baseAsset = baseAsset
            self.quoteAsset = quoteAsset
            self.amount = amount
            self.price = price
        }
    }
    
    public enum LoadingStatus {
        case loaded
        case loading
    }
}

extension CreateOffer.Model.Button {
    enum ButtonType {
        case buy
        case sell
    }
}

extension CreateOffer.Model.Field {
    enum FieldType {
        case price
        case amount
    }
}

// MARK: - Events

extension CreateOffer.Event {
    typealias Model = CreateOffer.Model
    
    enum ViewDidLoadSync {
        struct Request {}
        struct Response {
            let price: CreateOffer.Model.Amount
            let amount: CreateOffer.Model.Amount
            let total: CreateOffer.Model.Amount
        }
        struct ViewModel {
            let price: CreateOffer.Model.Amount
            let amount: CreateOffer.Model.Amount
            let total: String
        }
    }
    
    enum FieldEditing {
        struct Request {
            let field: CreateOffer.Model.Field
        }
        struct Response {
            let total: CreateOffer.Model.Amount
        }
        struct ViewModel {
            let total: String
        }
    }
    
    enum ButtonAction {
        enum Action {
            case offer(CreateOffer.Model.CreateOfferModel)
            case error(String)
        }
        struct Request {
            let type: CreateOffer.Model.Button.ButtonType
        }
        typealias Response = Action
        typealias ViewModel = Action
    }
    
    enum FieldStateDidChange {
        struct Response {
            let priceFieldIsFilled: Bool
            let amountFieldIsFilled: Bool
        }
        struct ViewModel {
            let priceTextFieldState: TextFieldState
            let amountTextFieldState: TextFieldState
        }
    }
    
    public struct LoadingStatusDidChange {
        public typealias Response =  Model.LoadingStatus
        public typealias ViewModel = Response
    }
}

extension CreateOffer.Event.FieldStateDidChange.ViewModel {
    enum TextFieldState {
        case normal
        case error
    }
}
