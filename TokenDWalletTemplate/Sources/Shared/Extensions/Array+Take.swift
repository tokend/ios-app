import Foundation

extension Array {
    
    func takeFirst(n: Int) -> [Element] {
        if self.isEmpty {
            return []
        } else if self.count >= n {
            return Array(self[0...(n-1)])
        } else {
            return Array(self[0...(self.count-1)])
        }
    }
}
