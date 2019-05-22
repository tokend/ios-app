import Foundation

extension Array where Element: Equatable {
    
    func indexOf(_ element: Element) -> Int? {
        for index in 0..<self.count where self[index] == element {
            return index
        }
        return nil
    }
}
