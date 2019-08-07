import Foundation

enum AppInfoUtils {
    
    enum PropertyKey: String {
        case bundleDisplayName = "CFBundleDisplayName"
    }
    
    static func hasValue(_ key: PropertyKey) -> Bool {
        guard let info = Bundle.main.infoDictionary else {
            return false
        }
        
        let value = info[key.rawValue]
        
        return value != nil
    }
    
    static func getValue<Type: Any>(_ key: PropertyKey, _ defaultValue: Type) -> Type {
        guard let info = Bundle.main.infoDictionary else {
            return defaultValue
        }
        
        guard let value = info[key.rawValue] as? Type else {
            return defaultValue
        }
        
        return value
    }
}
