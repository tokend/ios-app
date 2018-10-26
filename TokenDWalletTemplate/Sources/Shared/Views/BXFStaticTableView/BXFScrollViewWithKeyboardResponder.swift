import UIKit

class BXFScrollViewWithKeyboardResponder: UIScrollView { //KeyboardResponder
    
    var observers: [NSObjectProtocol] = []
    
    var hidesKeyboardOnTap: Bool {
        return true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        alwaysBounceVertical = true
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
    }
}
