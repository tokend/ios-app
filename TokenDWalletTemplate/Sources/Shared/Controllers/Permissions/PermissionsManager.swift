import Foundation
import AVFoundation

class PermissionsManager {
    typealias Completion = ((_ result: Result) -> Void)
    
    // MARK: - Public properties
    
    static let shared = PermissionsManager()
    
    // MARK: - Public
    
    func permissionRequested(resource: Resource, completion: @escaping (_ requested: Bool) -> Void) {
        switch resource {
            
        case .camera:
            if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func requestPermission(resource: Resource, completion: @escaping Completion) {
        switch resource {
            
        case .camera:
            self.requestCameraAccess(completion: completion)
        }
    }
    
    // MARK: - Private
    
    private func requestCameraAccess(completion: @escaping Completion) {
        guard AVCaptureDevice.authorizationStatus(for: .video) != .authorized else {
            completion(.granted)
            return
        }
        
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
            if granted {
                completion(.granted)
            } else {
                completion(.denied)
            }
        })
    }
}

extension PermissionsManager {
    enum Resource {
        case camera
    }
    
    enum Result {
        case granted
        case denied
    }
}
