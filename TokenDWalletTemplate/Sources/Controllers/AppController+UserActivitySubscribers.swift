import UIKit

extension AppController {
    
    // MARK: - Public
    
    func addUserAcivity(subscriber: UserActivitySubscriber) {
        if !self.userActivitySubscribers.contains(subscriber) {
            self.userActivitySubscribers.append(subscriber)
        }
    }
    
    func removeUserAcivity(subscriber: UserActivitySubscriber) {
        self.userActivitySubscribers.remove(object: subscriber)
    }
    
    // MARK: - Private
    
    internal func handle(userActivity: NSUserActivity) -> Bool {
        self.removeEmptyUserAcivitySubscribers()
        
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
            return self.handleUserActivityBrowsingWeb(url: url)
        }
        
        return false
    }
    
    private func removeEmptyUserAcivitySubscribers() {
        let liveSubscribers = self.userActivitySubscribers.filter { (subscriber) -> Bool in
            return subscriber.responder != nil
        }
        
        self.userActivitySubscribers = liveSubscribers
    }
    
    // MARK: Handlers
    
    private func handleUserActivityBrowsingWeb(url: URL) -> Bool {
        let browsingWebHandlers: [UserActivitySubscriberBrowsingWebHandler] = self.userActivitySubscribers
            .filter { (subscriber) -> Bool in
                switch subscriber.handler {
                    
                case .browsingWeb:
                    return true
                }
            }
            .map { (subscriber) -> UserActivitySubscriberBrowsingWebHandler in
                switch subscriber.handler {
                    
                case .browsingWeb(let handler):
                    return handler
                }
        }
        
        guard browsingWebHandlers.count > 0 else {
            return false
        }
        
        var handled = false
        for handler in browsingWebHandlers {
            if handler(url) {
                handled = true
            }
        }
        
        self.lastUserActivityURL = url
        
        return handled
    }
}

struct UserActivitySubscriber: Equatable {
    
    weak var responder: AnyObject?
    
    let handler: UserActivitySubscriberHandler
    
    static func urlHandler(
        responder: AnyObject,
        _ handler: @escaping UserActivitySubscriberBrowsingWebHandler
        ) -> UserActivitySubscriber {
        
        let subscriber = UserActivitySubscriber(
            responder: responder,
            handler: .browsingWeb(handler: handler)
        )
        
        return subscriber
    }
}

func ==(left: UserActivitySubscriber, right: UserActivitySubscriber) -> Bool {
    return left.responder === right.responder
}

typealias UserActivitySubscriberBrowsingWebHandler = ((_ url: URL) -> Bool)

enum UserActivitySubscriberHandler {
    case browsingWeb(handler: UserActivitySubscriberBrowsingWebHandler)
}
