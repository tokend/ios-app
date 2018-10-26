import UIKit

public final class QRCodeReaderOverlayView: UIView {
    
    // MARK: - Private properties
    
    private var overlay: CAShapeLayer = {
        var overlay = CAShapeLayer()
        overlay.backgroundColor = UIColor.clear.cgColor
        overlay.fillColor = UIColor.clear.cgColor
        overlay.strokeColor = Theme.Colors.mainColor.cgColor
        overlay.lineWidth = 2
        
        return overlay
    }()
    
    // MARK: - Overridden
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.commonInit()
    }
    
    // MARK: - Private
    
    private func commonInit() {
        self.backgroundColor = .clear
        self.clipsToBounds = true
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.setupOverlay()
    }
    
    private func setupOverlay() {
        self.layer.addSublayer(self.overlay)
    }
    
    // MARK: - Public
    
    public var overlayColor: UIColor = UIColor.white {
        didSet {
            self.overlay.strokeColor = self.overlayColor.cgColor
            self.setNeedsDisplay()
        }
    }
    
    public override func draw(_ rect: CGRect) {
        var innerRect = rect.insetBy(dx: 50, dy: 50)
        let minSize   = min(innerRect.width, innerRect.height)
        
        if innerRect.width != minSize {
            innerRect.origin.x   += (innerRect.width - minSize) / 2
            innerRect.size.width = minSize
        } else if innerRect.height != minSize {
            innerRect.origin.y    += (innerRect.height - minSize) / 2
            innerRect.size.height = minSize
        }
        
        self.overlay.path = UIBezierPath(roundedRect: innerRect, cornerRadius: 5).cgPath
    }
}
