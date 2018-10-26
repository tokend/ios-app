import Foundation

extension Hashable {
    private static func iterate() -> AnyIterator<Self> {
        var index = 0
        return AnyIterator {
            let next = withUnsafeBytes(of: &index) { $0.load(as: self) }
            if next.hashValue != index { return nil }
            index += 1
            return next
        }
    }
    
    static var values: [Self] {
        return Array(Self.iterate())
    }
}
