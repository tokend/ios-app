import Foundation

extension Array where Element: Equatable {
    mutating func remove(object: Element) {
        if let index: Int = firstIndex(of: object) {
            remove(at: index)
        }
    }
}
