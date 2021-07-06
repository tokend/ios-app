import UIKit

extension UIStackView {
    func removeArrangedSubviews() {
        for subview in arrangedSubviews {
            subview.removeFromSuperview()
        }
    }
}
