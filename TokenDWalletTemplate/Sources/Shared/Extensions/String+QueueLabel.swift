import Foundation

extension String {
    var queueLabel: String {
        return [self.appBundleIdentifier, "queue", self].joined(separator: ".")
    }
    
    private var appBundleIdentifier: String {
        return Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? "APP_ID"
    }
}
