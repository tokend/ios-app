import UIKit

public enum SaleInvest {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension SaleInvest.Model {
    public typealias CancellationError = SaleInvest.Event.InvestAction.Response.InvestError
    
    public struct SceneModel {
        let investorAccountId: String
        var inputAmount: Decimal
        var selectedBalance: BalanceDetails?
    }
    
    public struct BalanceDetails: Equatable {
        let asset: String
        let balance: Decimal
        let balanceId: String
        var prevOfferId: UInt64?
    }
    
    public struct SaleModel {
        let id: String
        let baseAsset: String
        let baseAssetName: String
        let defaultQuoteAsset: String
        let type: Int
        let ownerId: String
        let quoteAssets: [QuoteAsset]
        
        public struct QuoteAsset {
            let asset: String
            let currentCap: Decimal
            let price: Decimal
            let quoteBalanceId: String
        }
    }
    
    public struct SaleInvestModel {
        let baseAsset: String
        let quoteAsset: String
        let baseBalance: String
        let quoteBalance: String
        let isBuy: Bool
        let baseAmount: Decimal
        let quoteAmount: Decimal
        let baseAssetName: String
        let price: Decimal
        let fee: Decimal
        let type: Int
        let offerId: UInt64
        let prevOfferId: UInt64?
        let orderBookId: UInt64
    }
    
    public struct CancelInvestModel {
        let baseBalance: String
        let quoteBalance: String
        let price: Decimal
        let fee: Decimal
        let prevOfferId: UInt64
        let orderBookId: UInt64
    }
    
    public struct InvestingModel {
        var selectedBalance: BalanceDetails?
        var amount: Decimal
        let availableAmount: Decimal
        let isCancellable: Bool
        let actionTitle: String
    }
    
    struct InvestingViewModel {
        let availableAmount: String
        let inputAmount: Decimal
        let maxInputAmount: Decimal
        let selectedAsset: String?
        let isCancellable: Bool
        let actionTitle: String
    }
    
    public struct BalanceDetailsViewModel {
        let asset: String
        let balance: String
        let balanceId: String
    }
    
    public struct InvestmentOffer {
        let amount: Decimal
        let asset: String
        let id: UInt64
    }
    
    public struct AccountModel {
        let isVerified: Bool
    }
    
    public struct AssetModel {
        let code: String
    }
}

// MARK: - Events

extension SaleInvest.Event {
    public typealias Model = SaleInvest.Model
    
    // MARK: -
    
    public enum ViewDidLoad {
        public struct Request {}
    }
    
    public enum SceneUpdated {
        public struct Response {
            let model: Model.InvestingModel
        }
        public struct ViewModel {
            let viewModel: Model.InvestingViewModel
        }
    }
    
    public enum SelectBalance {
        public struct Request {}
        
        public struct Response {
            let balances: [Model.BalanceDetails]
        }
        
        public struct ViewModel {
            let balances: [Model.BalanceDetailsViewModel]
        }
    }
    
    public struct BalanceSelected {
        public struct Request {
            let balanceId: String
        }
        
        public struct Response {
            let updatedTab: Model.InvestingModel
        }
        
        public struct ViewModel {
            let viewModel: Model.InvestingViewModel
        }
    }
    
    public struct EditAmount {
        public struct Request {
            let amount: Decimal?
        }
    }
    
    public enum InvestAction {
        public struct Request {}
        
        public enum Response {
            case loading
            case loaded
            case failed(SaleInvest.Event.InvestAction.Response.InvestError)
            case succeeded(Model.SaleInvestModel)
        }
        
        public enum ViewModel {
            case loading
            case loaded
            case failed(errorMessage: String)
            case succeeded(Model.SaleInvestModel)
        }
    }
    
    public enum CancelInvestAction {
        public struct Request {}
        
        public enum Response {
            case loading
            case succeeded
            case failed(Model.CancellationError)
        }
        
        public enum ViewModel {
            case loading
            case succeeded
            case failed(errorMessage: String)
        }
    }
    
    public enum Error {
        public struct Response {
            let error: Swift.Error
        }
        
        public struct ViewModel {
            let message: String
        }
    }
}

extension SaleInvest.Event.InvestAction.Response {
    
    public enum InvestError: Swift.Error, LocalizedError {
        case baseBalanceIsNotFound(asset: String)
        case feeError(Error)
        case formatError
        case inputIsEmpty
        case insufficientFunds
        case investInOwnSaleIsForbidden
        case quoteAssetIsNotFound
        case quoteBalanceIsNotFound
        case saleIsNotFound
        case previousOfferIsNotFound
        case failedToCancelInvestment
        
        // MARK: - LocalizedError
        
        public var errorDescription: String? {
            switch self {
            case .inputIsEmpty:
                return Localized(.empty_amount)
            case .investInOwnSaleIsForbidden:
                return Localized(.investing_in_own_sale_is_forbidden)
            case .quoteBalanceIsNotFound:
                return Localized(.quote_balance_is_not_found)
            case .quoteAssetIsNotFound:
                return Localized(.quote_asset_is_not_found)
            case .saleIsNotFound:
                return Localized(.sale_is_not_found)
            case .baseBalanceIsNotFound(let asset):
                return Localized(
                    .balance_is_not_created,
                    replace: [
                        .balance_is_not_created_replace_asset: asset
                    ]
                )
            case .formatError:
                return Localized(.error_while_formatting_orderbookid)
            case .feeError(let error):
                let message = error.localizedDescription
                return Localized(
                    .fee_error,
                    replace: [
                        .fee_error_replace_message: message
                    ]
                )
            case .insufficientFunds:
                return Localized(.insufficient_funds)
                
            case .previousOfferIsNotFound:
                return Localized(.investment_to_be_cancelled_is_not_found)
                
            case .failedToCancelInvestment:
                return Localized(.failed_to_cancel_investment)
            }
        }
    }
}
