import UIKit
// Define NOTIFICATIONS in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use notifications
#if NOTIFICATIONS
import Firebase
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var appController: AppController!
    let rootNavigationController: RootNavigationViewController = RootNavigationViewController()

// Define NOTIFICATIONS in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use notifications
#if NOTIFICATIONS
    private lazy var notificationsRegisterer: FirebaseNotificationsRegistererProtocol? = initNotificationsRegisterer()
#else
    private var notificationsRegisterer: FirebaseNotificationsRegistererProtocol? = nil
#endif

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        let apiConfiguration: APIConfigurationModel
        do {
            apiConfiguration = try APIConfigurationFetcher.fetchApiConfigurationFromPlist("APIConfiguration")
        } catch let error {
            let message = error.localizedDescription
            fatalError("Failed to fetch apiConfiguration: \(message)")
        }

        initNotifications()

        self.appController = AppController(
            rootNavigation: self.rootNavigationController,
            apiConfigurationModel: apiConfiguration,
            notificationsRegisterer: notificationsRegisterer,
            launchOptions: launchOptions
        )
        self.rootNavigationController.appController = self.appController

        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = self.rootNavigationController
        self.window?.makeKeyAndVisible()

        return true
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
        ) -> Bool {

        return self.appController.applicationContinue(
            userActivity: userActivity,
            restorationHandler: restorationHandler
        )
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
        ) -> Bool {

        return self.appController.handleOpenURL(url: url, options: options)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        self.appController.applicationDidEnterBackground()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        self.appController.applicationWillEnterForeground()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        self.appController.applicationDidBecomeActive()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        self.appController.applicationWillResignActive()
    }
    // Define NOTIFICATIONS in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use notifications
    #if NOTIFICATIONS
    func initNotificationsRegisterer() -> FirebaseNotificationsRegistererProtocol { }
    #endif
}

extension AppDelegate {

    func initNotifications() {
        // Define NOTIFICATIONS in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use notifications
        #if NOTIFICATIONS
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self
        #endif
    }
}

// Define NOTIFICATIONS in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use notifications
#if NOTIFICATIONS
extension AppDelegate {

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {

        notificationsRegisterer?.didRegister(with: deviceToken)
        print(.log(message: deviceToken.hexadecimal().uppercased()))
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {

        notificationsRegisterer?.didFailToRegister(with: error)
        print(.log(message: error.localizedDescription))
    }
}
#endif

// Define NOTIFICATIONS in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use notifications
#if NOTIFICATIONS
extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {

        completionHandler([.alert, .badge, .sound])
    }
}
#endif
