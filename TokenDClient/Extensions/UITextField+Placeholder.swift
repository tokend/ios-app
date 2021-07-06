import UIKit

extension UITextField {
    
    @objc public var placeholderColor: UIColor? {
        get { attributedPlaceholder?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor }
        set {
            attributedPlaceholder = NSAttributedString(
                string: placeholder ?? "",
                attributes: [
                    .foregroundColor: newValue as Any
                ]
            )
        }
    }
}
