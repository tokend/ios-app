import UIKit

extension UISegmentedControl {
    func fillWithSegments(_ titles: [String], animated: Bool) {
        self.removeAllSegments()
        for title in titles {
            self.insertSegment(withTitle: title, at: self.numberOfSegments, animated: animated)
        }
    }
}
