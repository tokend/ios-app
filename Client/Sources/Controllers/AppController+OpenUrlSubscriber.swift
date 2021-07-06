import UIKit

extension AppController {
    
    // MARK: - Public
    
    public func addOpenURL(subscriber: OpenURLSubscriber) {
        if !self.openURLSubscribers.contains(subscriber) {
            self.openURLSubscribers.append(subscriber)
        }
    }
    
    public func removeOpenURL(subscriber: OpenURLSubscriber) {
        self.openURLSubscribers.remove(object: subscriber)
    }
    
    // MARK: - Private
    
    internal func handleOpenURL(
        url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any]
        ) -> Bool {
        
        self.removeEmptyOpenURLSubscribers()
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return false
        }
        
        let handlers: [OpenURLSubscriberHandler] = self.openURLSubscribers
            .map { (subscriber) -> OpenURLSubscriberHandler in
                
                return subscriber.handleOpenURL
        }
        
        guard handlers.count > 0 else {
            return false
        }
        
        var handled = false
        for handler in handlers {
            if handler(url, components, options) {
                handled = true
            }
        }
        
        self.lastOpenURL = url
        
        return handled
    }
    
    private func removeEmptyOpenURLSubscribers() {
        let liveSubscribers = self.openURLSubscribers.filter { (subscriber) -> Bool in
            return subscriber.responder != nil
        }
        
        self.openURLSubscribers = liveSubscribers
    }
}
