import Foundation

extension Array {
    func indexInBounds(_ index: Int) -> Bool {
        return 0..<count ~= index
    }
}
