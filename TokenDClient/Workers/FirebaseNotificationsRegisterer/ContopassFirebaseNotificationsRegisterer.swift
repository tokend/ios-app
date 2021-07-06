// Define NOTIFICATIONS in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use notifications
#if NOTIFICATIONS
import UIKit
import UserNotifications
import RxSwift
import RxCocoa
import Firebase

class ContopassFirebaseNotificationsRegisterer: NSObject {

    private let fcmTokenBehaviorRelay: BehaviorRelay<FirebaseNotificationsRegistererProtocol.FCMToken?>
    private var messaging: Messaging {
        let m: Messaging = .messaging()
        m.delegate = self
        return m
    }

    override init() {

        fcmTokenBehaviorRelay = .init(value: nil)

        super.init()
    }
}

// MARK: - Private methods

private extension ContopassFirebaseNotificationsRegisterer {

    func requestFCMToken() {
        messaging.token { [weak self] (token, error) in
            if let error = error {
                print(.log(message: error.localizedDescription))
            } else if let token = token {
                self?.fcmTokenBehaviorRelay.accept(token)
            }
        }
    }
}

// MARK: - MessagingDelegate

extension ContopassFirebaseNotificationsRegisterer: MessagingDelegate {

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        fcmTokenBehaviorRelay.accept(fcmToken)
    }
}

// MARK: - FirebaseNotificationsRegistererProtocol

extension ContopassFirebaseNotificationsRegisterer: FirebaseNotificationsRegistererProtocol {

    func registerForNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    func unregisterFromNotifications() {
        messaging.deleteToken { [weak self] (error) in
            if let error = error {
                print(.log(message: error.localizedDescription))
            } else {
                self?.fcmTokenBehaviorRelay.accept(nil)
            }
        }
    }

    func didRegister(with token: FirebaseNotificationsRegistererProtocol.DeviceToken) {
        #if DEBUG
        messaging.setAPNSToken(token, type: .sandbox)
        #elseif RELEASE
        messaging.setAPNSToken(token, type: .prod)
        #endif
        requestFCMToken()
    }

    func didFailToRegister(with error: Error) {
        print(.log(message: error.localizedDescription))
    }

    func observeFCMToken() -> Observable<FirebaseNotificationsRegistererProtocol.FCMToken?> {
        fcmTokenBehaviorRelay.asObservable().distinctUntilChanged()
    }
}
#endif
