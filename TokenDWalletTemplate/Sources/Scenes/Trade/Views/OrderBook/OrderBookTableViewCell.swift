import UIKit

protocol OrderBookTableViewCellProtocol {
    func setPrice(_ price: String)
    func setAmount(_ amount: String)
}

typealias OrderBookTableViewCell = OrderBookTableViewCellProtocol & UIView

struct OrderBookTableViewCellModel<CellType: OrderBookTableViewCell>: CellViewModel {
    
    let price: String
    let priceCurrency: String
    let amount: String
    let amountCurrency: String
    let isBuy: Bool
    let offer: Trade.Model.Offer
    
    var onClick: ((CellType) -> Void)?
    
    func setup(cell: CellType) {
        cell.setPrice(self.price)
        cell.setAmount(self.amount)
    }
}
