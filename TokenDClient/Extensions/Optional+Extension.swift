import Foundation

extension Optional where Wrapped == String {
    var isEmpty: Bool {
        (self ?? "").isEmpty
    }
}
