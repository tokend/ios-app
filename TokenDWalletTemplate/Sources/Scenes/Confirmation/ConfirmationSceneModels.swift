import Foundation

enum ConfirmationScene {
    
    // MARK: - Typealiases
    
    typealias CellIdentifier = String
    
    // MARK: -
    
    enum Model {}
    enum Event {}
    enum View {}
}

// MARK: - Models

extension ConfirmationScene.Model {
    typealias CellIdentifier = ConfirmationScene.CellIdentifier
    
    class SectionModel {
        var cells: [CellModel]
        
        init(cells: [CellModel]) {
            self.cells = cells
        }
    }
    
    class CellModel {
        let title: String
        var cellType: CellType
        let identifier: CellIdentifier
        
        init(
            title: String,
            cellType: CellType,
            identifier: CellIdentifier
            ) {
            
            self.title = title
            self.cellType = cellType
            self.identifier = identifier
        }
    }
    
    class SectionViewModel {
        var cells: [CellViewModel]
        
        init(cells: [CellViewModel]) {
            self.cells = cells
        }
    }
    
    class CellViewModel {
        let title: String
        var cellType: CellModel.CellType
        let identifier: CellIdentifier
        
        init(
            title: String,
            cellType: CellModel.CellType,
            identifier: CellIdentifier
            ) {
            
            self.title = title
            self.cellType = cellType
            self.identifier = identifier
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
    }
    
    struct SaleInvestModel {
        let baseAsset: String
        let quoteAsset: String
        let baseBalance: String
        let quoteBalance: String
        let isBuy: Bool
        let baseAmount: Decimal
        let quoteAmount: Decimal
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
        case textField(value: String?, placeholder: String?, maxCharacters: Int)
        case boolSwitch(value: Bool)
    }
}

extension ConfirmationScene.Event.ConfirmAction {
    enum ConfirmError: Error, LocalizedError {
        case failedToCreateBalance(asset: String)
        case failedToDecodeAccountId(String)
        case failedToDecodeBalanceId(String)
        case failedToEncodeDestinationAddress
        case networkInfoError(Error)
        case notEnoughData
        case notEnoughMoneyOnBalance(asset: String)
        case other(Error)
        case sendTransactionError(Error)
        
        var errorDescription: String? {
            switch self {
            case .failedToCreateBalance(let asset):
                return "Failed to create balance for asset \(asset)"
            case .failedToDecodeAccountId(let accountId):
                return "Failed to decode account id \(accountId)"
            case .failedToDecodeBalanceId(let balanceId):
                return "Failed to decode balance id \(balanceId)"
            case .failedToEncodeDestinationAddress:
                return "Failed to encode destination address"
            case .networkInfoError(let error):
                return "Network info error: \(error.localizedDescription)"
            case .notEnoughData:
                return "Not enough data"
            case .notEnoughMoneyOnBalance(let asset):
                return "Not enough money on balance \(asset)"
            case .other(let error):
                return "Request error: \(error.localizedDescription)"
            case .sendTransactionError(let error):
                return "Send transaction error: \(error.localizedDescription)"
            }
        }
    }
}
