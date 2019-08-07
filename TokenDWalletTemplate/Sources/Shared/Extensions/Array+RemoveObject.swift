import Foundation

extension Array where Element: Equatable {
    mutating func remove(object: Element) {
        if let index: Int = index(of: object) {
            remove(at: index)
        }
    }
}
