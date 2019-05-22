import UIKit
import Firebase

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    var appController: AppController!
    var rootNavigationController: RootNavigationViewController!
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
        ) -> Bool {
        
        //To enable crash reporting - add GoogleService-Info.plist into the project
        //FirebaseApp.configure()
        
        self.rootNavigationController = RootNavigationViewController()
        
        let apiConfiguration: APIConfigurationModel
        do {
            apiConfiguration = try APIConfigurationFetcher.fetchApiConfigurationFromPlist("APIConfiguration")
        } catch let error {
            let message = error.localizedDescription
            fatalError("Failed to fetch apiConfiguration: \(message)")
        }
        
        self.appController = AppController(
            rootNavigation: self.rootNavigationController,
            apiConfigurationModel: apiConfiguration,
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
}
