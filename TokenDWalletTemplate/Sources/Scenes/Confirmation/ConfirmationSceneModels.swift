import Foundation

enum ConfirmationScene {
    
    // MARK: - Typealiases
    
    // MARK: -
    
    enum CellIdentifier: String {
        case toPay
        case toPayAmount
        case toPayFee
        case toReceive
        case toReceiveAmount
        case toReceiveFee
        case recipient
        case amount
        case fee
        case recipientFee
        case payRecipientFee
        case description
        case token
        case investment
        case fixedFee
        case percentFee
        case destination
        case price
        case test
        case sale
        case total
    }
    
    enum Model {}
    enum Event {}
    enum View {}
}

// MARK: - Models

extension ConfirmationScene.Model {
    typealias CellIdentifier = ConfirmationScene.CellIdentifier
    
    class SectionModel {
        let title: String
        var cells: [CellModel]
        
        init(
            title: String,
            cells: [CellModel]
            ) {
            
            self.title = title
            self.cells = cells
        }
    }
    
    class CellModel {
        let hint: String?
        var cellType: CellType
        let identifier: CellIdentifier
        let isDisabled: Bool
        
        init(
            hint: String?,
            cellType: CellType,
            identifier: CellIdentifier,
            isDisabled: Bool = false
            ) {
            
            self.hint = hint
            self.cellType = cellType
            self.identifier = identifier
            self.isDisabled = isDisabled
        }
    }
    
    class SectionViewModel {
        let title: String
        var cells: [CellViewAnyModel]
        
        init(
            title: String,
            cells: [CellViewAnyModel]
            ) {
            
            self.title = title
            self.cells = cells
        }
    }
    
    class CellViewModel {
        let hint: String?
        var cellType: CellModel.CellType
        let identifier: CellIdentifier
        let isDisabled: Bool
        
        init(
            hint: String?,
            cellType: CellModel.CellType,
            identifier: CellIdentifier,
            isDisabled: Bool = false
            ) {
            
            self.hint = hint
            self.cellType = cellType
            self.identifier = identifier
            self.isDisabled = isDisabled
        }
    }
    
    struct WithdrawModel {
        let senderBalanceId: String
        let asset: String
        let amount: Decimal
        let recipientAddress: String
        let senderFee: FeeModel
    }
    
    struct SendPaymentModel {
        let senderBalanceId: String
        let asset: String
        let amount: Decimal
        let recipientNickname: String
        let recipientAccountId: String
        let senderFee: FeeModel
        let recipientFee: FeeModel
        let description: String
        let reference: String
    }
    
    struct SaleInvestModel {
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
    
    struct CreateOfferModel {
        let baseAsset: String
        let quoteAsset: String
        let isBuy: Bool
        let amount: Decimal
        let price: Decimal
        let fee: Decimal
    }
    
    struct FeeModel {
        let asset: String
        let fixed: Decimal
        let percent: Decimal
    }
}

// MARK: - Events

extension ConfirmationScene.Event {
    typealias CellIdentifier = ConfirmationScene.CellIdentifier
    
    enum ViewDidLoad {
        struct Request {}
        struct Response {
            
        }
        struct ViewModel {
            
        }
    }
    
    enum SectionsUpdated {
        struct Response {
            var sectionModels: [ConfirmationScene.Model.SectionModel]
        }
        struct ViewModel {
            var sectionViewModels: [ConfirmationScene.Model.SectionViewModel]
        }
    }
    
    enum TextFieldEdit {
        struct Request {
            let identifier: CellIdentifier
            let text: String?
        }
    }
    
    enum BoolSwitch {
        struct Request {
            let identifier: CellIdentifier
            let value: Bool
        }
    }
    
    enum ConfirmAction {
        struct Request {}
        
        enum Response {
            case loading
            case loaded
            case failed(ConfirmError)
            case succeeded
        }
        
        enum ViewModel {
            case loading
            case loaded
            case failed(errorMessage: String)
            case succeeded
        }
    }
}

// MARK: -

extension ConfirmationScene.Model.CellModel {
    enum CellType {
        case text(value: String?)
        case boolSwitch(value: Bool)
    }
}

extension ConfirmationScene.Event.ConfirmAction {
    enum ConfirmError: Error, LocalizedError {
        case failedToCreateBalance(asset: String)
        case failedToDecodeAccountId(AccountId)
        case failedToDecodeBalanceId(BalanceId)
        case failedToEncodeDestinationAddress
        case networkInfoError(Error)
        case notEnoughData
        case notEnoughMoneyOnBalance(asset: String)
        case other(Error)
        case sendTransactionError(Error)
        
        var errorDescription: String? {
            switch self {
            case .failedToCreateBalance(let asset):
                return Localized(
                    .failed_to_create_balance_for,
                    replace: [
                        .failed_to_create_balance_for_replace_asset: asset
                    ]
                )
            case .failedToDecodeAccountId(let accountId):
                let id = accountId.rawValue
                return Localized(
                    .failed_to_decode_account_id,
                    replace: [
                        .failed_to_decode_account_id_replace_id: id
                    ]
                )
            case .failedToDecodeBalanceId(let balanceId):
                let id = balanceId.rawValue
                return Localized(
                    .failed_to_decode_balance_id,
                    replace: [
                        .failed_to_decode_balance_id_replace_id: id
                    ]
                )
            case .failedToEncodeDestinationAddress:
                return Localized(.failed_to_encode_destination_address)
            case .networkInfoError(let error):
                let message = error.localizedDescription
                return Localized(
                    .network_info_error,
                    replace: [
                        .network_info_error_replace_message: message
                    ]
                )
            case .notEnoughData:
                return Localized(.not_enough_data)
            case .notEnoughMoneyOnBalance(let asset):
                return Localized(
                    .not_enough_money_on_balance,
                    replace: [
                        .not_enough_money_on_balance_replace_asset: asset
                    ]
                )
            case .other(let error):
                let message = error.localizedDescription
                return Localized(
                    .request_error,
                    replace: [
                        .request_error_replace_message: message
                    ]
                )
            case .sendTransactionError(let error):
                let message = error.localizedDescription
                return Localized(
                    .send_transaction_error,
                    replace: [
                        .send_transaction_error_replace_message: message
                    ]
                )
            }
        }
    }
    
    enum BalanceId: String {
        case baseBalance
        case quoteBalance
        case baseBalanceId
        case quoteBalanceId
        case senderBalanceId
        case recipientBalanceId
    }
    
    enum AccountId: String {
        case recipientAccountId
    }
}
