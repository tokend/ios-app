import UIKit

class BXFStaticTableViewInfoSection {
    
    var section: UIView = UIView()
    let header: BXFStaticTableViewSectionHeaderFooterView
    let footer: BXFStaticTableViewSectionHeaderFooterView
    
    init(header: String,
         footer: String) {
        self.header = BXFStaticTableViewSectionHeaderFooterView.instantiate(with: .header, text: header)
        self.header.setTopInset(12)
        self.header.setBottomInset(0)
        self.footer = BXFStaticTableViewSectionHeaderFooterView.instantiate(with: .footer, text: footer)
        self.footer.setTopInset(0)
    }
}
