import Foundation

class BXFStaticTableViewButtonCellModel: CellViewModel {
    
    typealias OnClickCallback = ((BXFStaticTableViewButtonCell) -> Void)
    
    var hashValue: Int {
        return title.hashValue ^ isEnabled.hashValue
    }
    
    static func ==(lhs: BXFStaticTableViewButtonCellModel, rhs: BXFStaticTableViewButtonCellModel) -> Bool {
        return lhs.title == rhs.title && lhs.isEnabled == rhs.isEnabled
    }
    
    let title: String
    var onClick: OnClickCallback?
    var isEnabled: Bool = true
    
    init(title: String, onClick: ((BXFStaticTableViewButtonCell) -> Void)?, isEnabled: Bool) {
        self.title = title
        self.onClick = onClick
        self.isEnabled = isEnabled
    }
    
    func setup(cell: BXFStaticTableViewButtonCell) {
        cell.onClick = onClick
        cell.actionButton.setTitle(title, for: .normal)
        cell.actionButton.isEnabled = isEnabled
    }
}
