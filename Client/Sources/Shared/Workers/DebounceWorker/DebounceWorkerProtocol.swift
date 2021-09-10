import Foundation

public protocol DebounceWorkerProtocol {
    func debounce(
        delay: Double,
        completion: @escaping () -> Void
    )
}
