import UIKit

class BXFStaticTableViewSection {
    var section: UIView = UIView()
    let header: BXFStaticTableViewSectionHeaderFooterView
    let cell: BXFStaticTableViewSectionCell
    let footer: BXFStaticTableViewSectionHeaderFooterView
    
    init(header: BXFStaticTableViewSectionHeaderFooterView,
         cell: BXFStaticTableViewSectionCell,
         footer: BXFStaticTableViewSectionHeaderFooterView) {
        self.header = header
        self.cell = cell
        self.footer = footer
    }
    
    func showError(_ error: String, withFooter: Bool = false) {
        footer.showError(error, withTitle: withFooter)
    }
    
    func hideError() {
        footer.hideError()
    }
    
//    func shake() {
//        let animationDuration: TimeInterval = 0.8
//        header.shake(
//            direction: .Horizontal,
//            totalDuration: animationDuration,
//            completion: nil)
//        footer.shake(
//            direction: .Horizontal,
//            totalDuration: animationDuration,
//            completion: nil)
//        cell.shake(
//            direction: .Horizontal,
//            totalDuration: animationDuration,
//            completion: nil)
//    }
}
