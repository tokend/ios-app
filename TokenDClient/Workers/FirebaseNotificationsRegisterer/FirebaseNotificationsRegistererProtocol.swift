import Foundation
import RxSwift

protocol FirebaseNotificationsRegistererProtocol {

    typealias DeviceToken = Data
    typealias FCMToken = String

    func registerForNotifications()
    func unregisterFromNotifications()

    func didRegister(with token: DeviceToken)
    func didFailToRegister(with error: Swift.Error)

    func observeFCMToken() -> Observable<FCMToken?>
}
