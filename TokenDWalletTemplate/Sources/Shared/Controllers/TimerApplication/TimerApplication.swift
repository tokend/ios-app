import UIKit
import RxSwift
import RxCocoa

class TimerUIApplication: UIApplication {
    
    // MARK: - Public properties
    
    private var disposableSubscribers: [SubscribeToken: Disposable] = [:]
    
    private var idleTimerEnabled: Bool = false
    private var idleTimer: Timer?
    
    // MARK: - Overridden
    
    override func sendEvent(_ event: UIEvent) {
        super.sendEvent(event)
        
        guard event.type == .touches else {
            return
        }
        
        if let touches = event.allTouches {
            for touch in touches where touch.phase == .began {
                self.resetIdleTimer()
            }
        }
    }
    
    // MARK: - Public
    
    static func startIdleTimer() {
        guard let timerApplication = UIApplication.shared as? TimerUIApplication else {
            return
        }
        
        timerApplication.startIdleTimer()
    }
    
    static func stopIdleTimer() {
        guard let timerApplication = UIApplication.shared as? TimerUIApplication else {
            return
        }
        
        timerApplication.stopIdleTimer()
    }
    
    func startIdleTimer() {
        self.idleTimerEnabled = true
        
        self.resetIdleTimer()
    }
    
    func stopIdleTimer() {
        self.idleTimerEnabled = false
        
        self.resetIdleTimer()
    }
    
    func resetIdleTimer() {
        self.idleTimer?.invalidate()
        self.idleTimer = nil
        
        guard self.idleTimerEnabled else { return }
        
        self.idleTimer = Timer.scheduledTimer(
            withTimeInterval: SignedInFlowController.userActionsTimeout,
            repeats: false,
            block: { [weak self] _ in
                self?.idleTimerExceeded()
        })
    }
    
    typealias SubscribeToken = Int
    static let SubscribeTokenInvalid: SubscribeToken = 0
    static func subscribeForTimeoutNotification(handler: @escaping () -> Void) -> SubscribeToken {
        guard let timerApplication = UIApplication.shared as? TimerUIApplication else {
            return SubscribeTokenInvalid
        }
        
        let disposable = NotificationCenter.default.rx
            .notification(.ApplicationDidTimeoutNotification, object: nil)
            .subscribe(onNext: { _ in
                handler()
            })
        
        var token: Int = Int(arc4random())
        while timerApplication.disposableSubscribers[token] != nil {
            token = Int(arc4random())
        }
        
        timerApplication.disposableSubscribers[token] = disposable
        
        return token
    }
    
    static func unsubscribeFromTimeoutNotification(_ token: SubscribeToken) {
        guard let timerApplication = UIApplication.shared as? TimerUIApplication else {
            return
        }
        
        guard let disposable = timerApplication.disposableSubscribers[token] else {
            return
        }
        
        timerApplication.disposableSubscribers[token] = nil
        disposable.dispose()
    }
    
    // MARK: - Private
    
    private func idleTimerExceeded() {
        NotificationCenter.default.post(name: .ApplicationDidTimeoutNotification, object: nil)
    }
}

extension Notification.Name {
    static let ApplicationDidTimeoutNotification = Notification.Name(rawValue: "AppTimeout")
}
