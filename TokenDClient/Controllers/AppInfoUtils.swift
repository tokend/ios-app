import Foundation

enum AppInfoUtils {
    
    enum PropertyKey: String {
        case bundleDisplayName = "CFBundleDisplayName"
    }
    
    static func hasValue(_ key: PropertyKey) -> Bool {
        
        return getValue(key) != nil
    }
    
    static func getValue<Type: Any>(_ key: PropertyKey, _ defaultValue: Type) -> Type {
        
        guard let value = getValue(key) as? Type else {
            return defaultValue
        }
        
        return value
    }
    
    private static func getValue(_ key: PropertyKey) -> Any? {
        
        guard let info = Bundle.main.infoDictionary else {
            return nil
        }
        
        return info[key.rawValue]
    }
}
