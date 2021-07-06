import UIKit

public struct OpenURLSubscriber: Equatable {
    
    public weak var responder: AnyObject?
    
    public let handleOpenURL: OpenURLSubscriberHandler
    
    public init(
        responder: AnyObject?,
        handleOpenURL: @escaping OpenURLSubscriberHandler
        ) {
        
        self.responder = responder
        self.handleOpenURL = handleOpenURL
    }
}

public func ==(left: OpenURLSubscriber, right: OpenURLSubscriber) -> Bool {
    return left.responder === right.responder
}

public typealias OpenURLSubscriberHandler = (
    _ url: URL,
    _ urlComponents: URLComponents,
    _ options: [UIApplication.OpenURLOptionsKey: Any]
    ) -> Bool
