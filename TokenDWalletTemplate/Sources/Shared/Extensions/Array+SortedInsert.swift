import Foundation

extension Array where Element: Comparable {
    
    public typealias SortedInsertComparator = (
        _ upper: Element?,
        _ lower: Element?,
        _ element: Element
        ) -> Bool
    
    public mutating func sortedInsert(_ element: Element) {
        guard self.count > 0 else {
            self.append(element)
            return
        }
        
        for index in -1 ..< self.count {
            let upper: Element?
            let lower: Element?
            let insertIndex: Int
            
            if index == -1 {
                upper = nil
                lower = self.first
                insertIndex = 0
            } else if index == self.count - 1 {
                upper = self.last
                lower = nil
                insertIndex = self.count
            } else {
                upper = self[index]
                lower = self[index + 1]
                insertIndex = index + 1
            }
            
            let comparator: SortedInsertComparator = { (upper, lower, element) in
                if let upper = upper, let lower = lower {
                    return (upper <= element) && (element <= lower)
                } else if let upper = upper {
                    return (upper <= element)
                } else if let lower = lower {
                    return (element <= lower)
                } else {
                    return true
                }
            }
            
            let result = comparator(upper, lower, element)
            if result {
                self.insert(element, at: insertIndex)
                break
            }
        }
    }
}
