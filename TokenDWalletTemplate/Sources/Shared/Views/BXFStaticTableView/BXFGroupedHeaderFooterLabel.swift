import UIKit

class BXFGroupedHeaderFooterLabel: BXFLabelWithInsets {
    static func headerFooterLabel() -> BXFGroupedHeaderFooterLabel {
        let label = BXFGroupedHeaderFooterLabel()
//        label.textColor = UIColor.TableView.Grouped.headerFooter
//        label.font = UITableView.fontForHeaderFooter
        label.textAlignment = .left
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }
}
