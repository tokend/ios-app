import UIKit

class LocalizationManager {
    
    static func localizedString(key: LocKey) -> String {
        return NSLocalizedString(key.rawValue, comment: "")
    }
    
    static func localizedString(key: LocKey, replace: [ LocKey: Any ]) -> String {
        var localizedString = NSLocalizedString(key.rawValue, comment: "")
        
        for (key, value) in replace {
            if let startIndex = key.rawValue.endIndex(of: "replace_") {
                let valueName = key.rawValue[startIndex...]
                let replaceKey = "$(\(valueName))"
                localizedString = localizedString.replacingOccurrences(of: replaceKey, with: "\(value)")
            }
        }
        
        return localizedString
    }
    
    static func localizedPlural(forKey: String, number: Int) -> String {
        let format = NSLocalizedString(forKey, comment: "")
        return String.localizedStringWithFormat(format, number)
    }
}

// swiftlint:disable identifier_name
func Localized(_ key: LocKey) -> String {
    return LocalizationManager.localizedString(key: key)
}

func Localized(_ key: LocKey, replace: [ LocKey: Any ]) -> String {
    return LocalizationManager.localizedString(key: key, replace: replace)
}
// swiftlint:enable identifier_name
