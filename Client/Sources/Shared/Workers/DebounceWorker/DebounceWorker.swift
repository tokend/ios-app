import Foundation

public class Debouncer {
    
    public typealias Completion = () -> Void
    
    // MARK: - Private properties
    
    private var timer: Timer?
    private var completion: Completion?
    
    // MARK: - Private methods
    
    @objc private func executeCompletion() {
        self.completion?()
        self.completion = nil
    }
}

// MARK: - Public methods

public extension Debouncer {
    
    func debounce(
        delay: Double,
        completion: @escaping Completion
    ) {
        
        self.timer?.invalidate()
        self.completion = completion
        
        self.timer = Timer.scheduledTimer(
            timeInterval: delay,
            target: self,
            selector: #selector(executeCompletion),
            userInfo: nil,
            repeats: false
        )
    }
}
