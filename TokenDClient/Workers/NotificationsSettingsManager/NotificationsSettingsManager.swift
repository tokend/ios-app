import Foundation
import RxSwift
import RxCocoa
import TokenDSDK

class NotificationsSettingsManager {

    private struct Value: Codable {

        let allTopics: Bool
    }

    // MARK: - Private properties

    private let notificationsEnabledBehaviorRelay: BehaviorRelay<Bool?> = .init(value: nil)
    private let api: API
    private let userDataProvider: UserDataProviderProtocol

    private var settingsKey: String { "notifications_topics_availability" }

    // MARK: - 

    init(
        api: API,
        userDataProvider: UserDataProviderProtocol
    ) {

        self.api = api
        self.userDataProvider = userDataProvider

        fetchNotificationSettings()
    }
}

// MARK: - Private methods

private extension NotificationsSettingsManager {

    func fetchNotificationSettings() {
        let baseUrl = api.baseApiStack.apiConfiguration.urlString
        let url = baseUrl/"identities"/userDataProvider.walletData.accountId/"settings"/settingsKey

        struct NotificationsTopicsAvailability: Codable {

            let data: Data

            struct Data: Codable {

                let attributes: Attributes

                struct Attributes: Codable {

                    let value: Value?
                }
            }
        }

        let requestMethod: RequestMethod = .get
        api.baseApiStack.requestSigner.sign(
            request: .init(
                baseUrlString: baseUrl,
                urlString: url,
                httpMethod: requestMethod
            ),
            sendDate: Date(),
            completion: { [weak self] (signedHeaders) in
                self?.api.network.responseObject(
                    NotificationsTopicsAvailability.self,
                    url: url,
                    method: requestMethod,
                    parameters: nil,
                    encoding: .url,
                    headers: signedHeaders,
                    completion: { [weak self] (result) in

                        switch result {

                        case .success(let data):
                            let enabled: Bool = data.data.attributes.value?.allTopics ?? true
                            self?.notificationsEnabledBehaviorRelay.accept(enabled)

                        case .failure:
                            self?.notificationsEnabledBehaviorRelay.accept(false)
                        }
                    }
                )
            })
    }
}

// MARK: - NotificationsSettingsManagerProtocol

extension NotificationsSettingsManager: NotificationsSettingsManagerProtocol {

    var notificationsEnabled: Bool? { notificationsEnabledBehaviorRelay.value }

    func setNotificationsEnabled(_ enabled: Bool) {
        let baseUrl = api.baseApiStack.apiConfiguration.urlString
        let url = baseUrl/"identities"/userDataProvider.walletData.accountId/"settings"

        struct NotificationsTopicsAvailability: Codable {

            let data: Data

            struct Data: Codable {

                let attributes: Attributes

                struct Attributes: Codable {

                    let key: String
                    let value: Value
                }
            }
        }
        let notificationsData: NotificationsTopicsAvailability = .init(
            data: .init(
                attributes: .init(
                    key: settingsKey,
                    value: .init(
                        allTopics: enabled
                    )
                )
            )
        )

        guard let data = try? notificationsData.encode()
        else {
            return
        }

        notificationsEnabledBehaviorRelay.accept(enabled)
        let requestMethod: RequestMethod = .put
        api.baseApiStack.requestSigner.sign(
            request: .init(
                baseUrlString: baseUrl,
                urlString: url,
                httpMethod: requestMethod
            ),
            sendDate: Date(),
            completion: { [weak self] (signedHeaders) in
                self?.api.network.responseDataEmpty(
                    url: url,
                    method: requestMethod,
                    headers: signedHeaders,
                    bodyData: data,
                    completion: { [weak self] (result) in

                        switch result {

                        case .success:
                            break

                        case .failure:
                            self?.notificationsEnabledBehaviorRelay.accept(!enabled)
                        }
                    }
                )
            })
    }

    func observeNotificationsEnabled() -> Observable<Bool?> {
        notificationsEnabledBehaviorRelay.asObservable()
    }
}
