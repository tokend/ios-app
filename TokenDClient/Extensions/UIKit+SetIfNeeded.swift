import UIKit

extension UILabel {

    func setTextIfNeeded(_ text: String?) {
        if self.text != text {
            self.text = text
        }
    }
}

extension UIPageControl {

    func setNumberOfPagesIfNeeded(_ number: Int) {
        if self.numberOfPages != number {
            self.numberOfPages = number
        }
    }
}

extension UIButton {
    
    func setTitleIfNeeded(_ title: String?) {
        if self.titleLabel?.text != title {
            self.titleLabel?.text = title
        }
    }
}
