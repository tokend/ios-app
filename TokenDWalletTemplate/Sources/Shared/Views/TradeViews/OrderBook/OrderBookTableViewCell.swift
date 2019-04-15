import UIKit

public protocol OrderBookTableViewCellProtocol {
    func setPrice(_ price: String)
    func setAmount(_ amount: String)
}

public typealias OrderBookTableViewCell = OrderBookTableViewCellProtocol & UIView

public struct OrderBookTableViewCellModel<CellType: OrderBookTableViewCell>: CellViewModel {
    
    public struct Amount {
        
        public let value: Decimal
        public let currency: String
        
        public init(
            value: Decimal,
            currency: String
            ) {
            
            self.value = value
            self.currency = currency
        }
    }
    
    public struct Offer {
        
        public let amount: Amount
        public let price: Amount
        public let isBuy: Bool
        
        public init(
            amount: Amount,
            price: Amount,
            isBuy: Bool
            ) {
            
            self.amount = amount
            self.price = price
            self.isBuy = isBuy
        }
    }
    
    public let price: String
    public let priceCurrency: String
    public let amount: String
    public let amountCurrency: String
    public let isBuy: Bool
    public let offer: Offer
    public var onClick: ((CellType) -> Void)?
    
    public init(
        price: String,
        priceCurrency: String,
        amount: String,
        amountCurrency: String,
        isBuy: Bool,
        offer: Offer,
        onClick: ((CellType) -> Void)?
        ) {
        
        self.price = price
        self.priceCurrency = priceCurrency
        self.amount = amount
        self.amountCurrency = amountCurrency
        self.isBuy = isBuy
        self.offer = offer
        self.onClick = onClick
    }
    
    public func setup(cell: CellType) {
        cell.setPrice(self.price)
        cell.setAmount(self.amount)
    }
}
