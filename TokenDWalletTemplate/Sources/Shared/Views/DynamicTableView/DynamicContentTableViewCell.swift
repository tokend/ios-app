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
    
    // MARK: -
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.customInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.customInit()
    }
    
    private func customInit() {
        self.backgroundColor = UIColor.clear
        self.contentView.backgroundColor = UIColor.clear
    }
}
