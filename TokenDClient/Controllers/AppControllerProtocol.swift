import UIKit

protocol AppControllerProtocol: AnyObject {
    func updateFlowControllerStack(_ configuration: APIConfigurationModel, _ keychainManager: KeychainManagerProtocol)
    
    func addUserAcivity(subscriber: UserActivitySubscriber)
    func removeUserAcivity(subscriber: UserActivitySubscriber)
    
    func onRootDidAppear()
    
    func getLaunchOptions() -> [UIApplication.LaunchOptionsKey: Any]?
    func launchOptionsUrlHandled(url: URL)
    func getLastUserActivityWebLink() -> URL?
    func lastUserActivityWebLinkHandled(url: URL)
    
    func addOpenURL(subscriber: OpenURLSubscriber)
    func removeOpenURL(subscriber: OpenURLSubscriber)
}
