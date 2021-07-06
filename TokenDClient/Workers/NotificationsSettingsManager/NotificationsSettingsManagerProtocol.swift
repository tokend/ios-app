import Foundation
import RxSwift

protocol NotificationsSettingsManagerProtocol {

    var notificationsEnabled: Bool? { get }

    func setNotificationsEnabled(_ enabled: Bool)
    func observeNotificationsEnabled() -> Observable<Bool?>
}
