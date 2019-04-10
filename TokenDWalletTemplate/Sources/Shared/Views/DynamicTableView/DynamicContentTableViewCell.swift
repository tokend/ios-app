import UIKit

public class DynamicContentTableViewCell: UITableViewCell {
    
    public static let identifier: String = "DynamicContentTableViewCell"
    
    // MARK: - Public properties
    
    public var content: UIView? {
        willSet {
            if let prev = self.content {
                prev.removeFromSuperview()
            }
        }
        didSet {
            if let new = self.content {
                self.contentView.addSubview(new)
                new.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
            }
        }
    }
}
