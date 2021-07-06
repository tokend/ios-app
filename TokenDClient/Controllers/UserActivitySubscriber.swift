import Foundation

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
