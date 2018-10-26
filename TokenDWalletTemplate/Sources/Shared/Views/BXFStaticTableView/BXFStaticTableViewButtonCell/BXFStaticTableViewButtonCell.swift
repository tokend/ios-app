import UIKit

class BXFStaticTableViewButtonCell: UIControl {
    
    @IBOutlet weak var actionButton: UIButton! {
        didSet {
            actionButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        }
    }
    
    override var isEnabled: Bool {
        get {
            return self.actionButton.isEnabled
        }
        set {
            self.actionButton.isEnabled = newValue
        }
    }
    
    public var onClick: ((BXFStaticTableViewButtonCell) -> Void)? = { _ in }
    
    @objc public func buttonAction() {
        onClick?(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = UIColor.black
    }
    
    static func instantiate() -> BXFStaticTableViewButtonCell {
        guard let cell = BXFStaticTableViewButtonCell.loadFromNib()
            else {
                return BXFStaticTableViewButtonCell()
        }
        
        return cell
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        
        if isTouchInside && actionButton.isEnabled {
            onClick?(self)
        }
    }
}
