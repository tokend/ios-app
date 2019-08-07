import UIKit

class BXFStaticTableViewInputSection {
    
    static func create(
        with title: String?,
        cell cellContent: UIView,
        footer description: String?
        ) -> BXFStaticTableViewSection {
        
        let header = BXFStaticTableViewSectionHeaderFooterView.instantiate(with: .header, text: title)
        
        let cell: BXFStaticTableViewSectionCell = BXFStaticTableViewSectionCell.instantiate(
            with: cellContent,
            border: true
        )
        
        let footer = BXFStaticTableViewSectionHeaderFooterView.instantiate(with: .footer, text: description)
        
        return BXFStaticTableViewSection(header: header, cell: cell, footer: footer)
    }
}
