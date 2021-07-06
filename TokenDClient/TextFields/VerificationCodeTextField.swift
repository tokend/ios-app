import UIKit

class VerificationCodeTextField: UITextField {

    var onDeleteBackward: (() -> Void)?

    override var selectedTextRange: UITextRange? {
        didSet {
            super.selectedTextRange = textRange(from: endOfDocument, to: endOfDocument)
        }
    }

    override func deleteBackward() {
        super.deleteBackward()
        onDeleteBackward?()
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
}
