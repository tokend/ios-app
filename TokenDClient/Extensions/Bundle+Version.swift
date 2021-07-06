import Foundation

extension Bundle {
    
    var shortVersion: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    var bundleVersion: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}
