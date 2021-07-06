import UIKit

struct ApplicationEventsObserver: Equatable {
    
    typealias SimpleEventHandler = () -> Void
    
    weak var observer: AnyObject?
    let appDidEnterBackground: SimpleEventHandler?
    let appWillEnterForeground: SimpleEventHandler?
    
    // MARK: -
    
    init(
        observer: AnyObject?,
        appDidEnterBackground: SimpleEventHandler? = nil,
        appWillEnterForeground: SimpleEventHandler? = nil
        ) {
        
        self.observer = observer
        self.appDidEnterBackground = appDidEnterBackground
        self.appWillEnterForeground = appWillEnterForeground
    }
    
    // MARK: - Equatable
    
    static func ==(left: ApplicationEventsObserver, right: ApplicationEventsObserver) -> Bool {
        return left.observer === right.observer
    }
}

protocol ApplicationEventsControllerProtocol {
    func add(observer: ApplicationEventsObserver)
}

class ApplicationEventsController: ApplicationEventsControllerProtocol {
    
    // MARK: - Properties
    
    private var observers: [ApplicationEventsObserver] = []
    
    static let shared = ApplicationEventsController()
    
    // MARK: - Public
    
    func add(observer: ApplicationEventsObserver) {
        if !self.observers.contains(observer) {
            self.observers.append(observer)
        }
    }
    
    func remove(observer: ApplicationEventsObserver) {
        self.observers.remove(object: observer)
    }
    
    // MARK: - Private
    
    private init() {
        self.subscribeForEvents()
    }
    
    private func subscribeForEvents() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    // MARK: - Notifications
    
    @objc private func applicationDidEnterBackground() {
        self.enumerateObservers { (observer) in
            observer.appDidEnterBackground?()
        }
    }
    
    @objc private func applicationWillEnterForeground() {
        self.enumerateObservers { (observer) in
            observer.appWillEnterForeground?()
        }
    }
    
    private func enumerateObservers(_ closure: (ApplicationEventsObserver) -> Void) {
        let allObservers = self.observers
        for observer in allObservers {
            if observer.observer == nil {
                self.observers.remove(object: observer)
            } else {
                closure(observer)
            }
        }
    }
}
