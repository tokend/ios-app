import Foundation
import AVFoundation
import Contacts
import UserNotifications
import CoreLocation

class PermissionsManager: NSObject {
    typealias Completion = ((_ result: Result) -> Void)
    
    private var locationPermissionCompletion: Completion? = nil
    
    // MARK: - Public properties
    
    static let shared = PermissionsManager()
    
    private lazy var locationManager: CLLocationManager = .init()
    
    // MARK: - Public
    
    func permissionRequested(resource: Resource, completion: @escaping (_ requested: Bool) -> Void) {
        switch resource {
            
        // Define CAMERA in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use contacts
        #if CAMERA
        case .camera:
            if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
                completion(false)
            } else {
                completion(true)
            }
        #endif
            
        // Define CONTACTS in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use contacts
        #if CONTACTS
        case .contacts:
            if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
                completion(false)
            } else {
                completion(true)
            }
        #endif

        // Define NOTIFICATIONS in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use notifications
        #if NOTIFICATIONS
        case .notifications:
            UNUserNotificationCenter
                .current()
                .getNotificationSettings(
                    completionHandler: { (settings) in
                        if settings.authorizationStatus == .notDetermined {
                            completion(false)
                        } else {
                            completion(true)
                        }
                    }
                )
        #endif
        
        // Define LOCATION in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use location
        #if LOCATION
        case .location:
            if CLLocationManager.authorizationStatus() == .notDetermined {
                completion(false)
            } else {
                completion(true)
            }
        #endif
        
        case .none:
            completion(true)
        }
    }
    
    func requestPermission(resource: Resource, completion: @escaping Completion) {
        switch resource {
            
        // Define CAMERA in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use contacts
        #if CAMERA
        case .camera:
            self.requestCameraAccess(completion: completion)
        #endif
        // Define CONTACTS in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use contacts
        #if CONTACTS
        case .contacts:
            self.requestContactsAccess(completion: completion)
        #endif
        // Define NOTIFICATIONS in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use notifications
        #if NOTIFICATIONS
        case .notifications:
            self.requestNotificationsAccess(completion: completion)
        #endif
        // Define LOCATION in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use location
        #if LOCATION
        case .location:
            self.requestLocationAccess(completion: completion)
        #endif

        case .none:
            completion(.granted)
        }
    }
    
    // MARK: - Private
    
    // Define CAMERA in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use contacts
    #if CAMERA
    private func requestCameraAccess(completion: @escaping Completion) {
        guard AVCaptureDevice.authorizationStatus(for: .video) != .authorized else {
            completion(.granted)
            return
        }
        
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
            if granted {
                DispatchQueue.main.async {
                    completion(.granted)
                }
            } else {
                DispatchQueue.main.async {
                    completion(.denied)
                }
            }
        })
    }
    #endif
    
    // Define CONTACTS in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use contacts
    #if CONTACTS
    private func requestContactsAccess(completion: @escaping Completion) {
        
        guard CNContactStore.authorizationStatus(for: .contacts) != .authorized else {
            completion(.granted)
            return
        }
        
        CNContactStore().requestAccess(
            for: .contacts,
            completionHandler: { (granted, error) in
                // TODO: Handle error
                if granted {
                    DispatchQueue.main.async {
                        completion(.granted)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.denied)
                    }
                }
            }
        )
    }
    #endif
    
    // Define NOTIFICATIONS in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use notifications
    #if NOTIFICATIONS
    private func requestNotificationsAccess(completion: @escaping Completion) {

        UNUserNotificationCenter
            .current()
            .getNotificationSettings(
                completionHandler: { (settings) in
                    if settings.authorizationStatus == .authorized {
                        DispatchQueue.main.async {
                            completion(.granted)
                        }
                        return
                    }

                    UNUserNotificationCenter
                        .current()
                        .requestAuthorization(
                            options: [.alert, .badge, .sound],
                            completionHandler: { (granted, error) in
                                // TODO: Handle error
                                if granted {
                                    DispatchQueue.main.async {
                                        completion(.granted)
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        completion(.denied)
                                    }
                                }
                            }
                        )
                }
            )
    }
    #endif
    
    // Define LOCATION in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use location
    #if LOCATION
    private func requestLocationAccess(completion: @escaping Completion) {
        
        if CLLocationManager.authorizationStatus() == .authorizedAlways
            || CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            completion(.granted)
        } else {
            self.locationPermissionCompletion = completion
            self.locationManager.delegate = self
            self.locationManager.requestAlwaysAuthorization()
        }
    }
    #endif
}

extension PermissionsManager {
    enum Resource {
        // Define CAMERA in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use contacts
        #if CAMERA
        case camera
        #endif
        // Define CONTACTS in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use contacts
        #if CONTACTS
        case contacts
        #endif
        // Define NOTIFICATIONS in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use notifications
        #if NOTIFICATIONS
        case notifications
        #endif
        // Define LOCATION in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use location
        #if LOCATION
        case location
        #endif
        case none
    }
    
    enum Result {
        case granted
        case denied
    }
}

// Define LOCATION in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use location
#if LOCATION
extension PermissionsManager: CLLocationManagerDelegate {
    
    func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        
        switch status {
        
        case .authorizedAlways,
             .authorizedWhenInUse:
            self.locationPermissionCompletion?(.granted)
            self.locationPermissionCompletion = nil
            manager.delegate = nil
            
        case .notDetermined:
            self.requestLocationAccess(completion: locationPermissionCompletion ?? { (_) in })
        
        case .denied,
             .restricted:
            self.locationPermissionCompletion?(.denied)
            self.locationPermissionCompletion = nil
            manager.delegate = nil
            
        default:
            self.locationPermissionCompletion?(.denied)
            self.locationPermissionCompletion = nil
            manager.delegate = nil
        }
    }
}
#endif
