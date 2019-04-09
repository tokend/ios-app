import UIKit

class PermissionRequestFlowController: BaseFlowController {
    
    // MARK: - Public properties
    
    let resource: PermissionsManager.Resource
    let onGranted: () -> Void
    let onDenied: () -> Void
    
    // MARK: - Private
    
    var appSystemSettingsRequested: Bool = false
    
    // MARK: -
    
    init(
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        rootNavigation: RootNavigationProtocol,
        resource: PermissionsManager.Resource,
        onGranted: @escaping () -> Void,
        onDenied: @escaping () -> Void
        ) {
        
        self.resource = resource
        self.onGranted = onGranted
        self.onDenied = onDenied
        
        super.init(
            appController: appController,
            flowControllerStack: flowControllerStack,
            rootNavigation: rootNavigation
        )
    }
    
    // MARK: - Public
    
    func run() {
        self.requestPermissions(handleRepeatedRequest: true)
    }
    
    // MARK: - Overridden
    
    override func applicationDidBecomeActive() {
        if self.appSystemSettingsRequested {
            self.appSystemSettingsRequested = false
            self.requestPermissions(handleRepeatedRequest: false)
        }
    }
    
    // MARK: - Private
    
    private func requestPermissions(handleRepeatedRequest: Bool) {
        let resource = self.resource
        
        PermissionsManager.shared.permissionRequested(
            resource: resource,
            completion: { [weak self] (permissionRequested) in
                
                PermissionsManager.shared.requestPermission(
                    resource: resource,
                    completion: { (result) in
                        switch result {
                            
                        case .denied:
                            if permissionRequested, handleRepeatedRequest {
                                self?.handleDeniedOnRepeatedRequest()
                            } else {
                                self?.onDenied()
                            }
                            
                        case .granted:
                            self?.onGranted()
                        }
                })
        })
    }
    
    private func handleDeniedOnRepeatedRequest() {
        let alert = UIAlertController(
            title: Localized(.permissions_denied),
            message: Localized(.you_can_grant_permissions),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: Localized(.settings),
            style: .default,
            handler: { [weak self] (_) in
                self?.appSystemSettingsRequested = true
                
                guard
                    let url = URL(string: UIApplication.openSettingsURLString),
                    UIApplication.shared.canOpenURL(url)
                    else {
                        self?.onDenied()
                        return
                }
                
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }))
        
        alert.addAction(UIAlertAction(
            title: Localized(.cancel),
            style: .cancel,
            handler: { [weak self] (_) in
                self?.onDenied()
        }))
        
        self.rootNavigation.presentAlert(alert, animated: true, completion: nil)
    }
}
