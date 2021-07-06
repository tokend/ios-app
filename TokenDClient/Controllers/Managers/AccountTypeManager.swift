import Foundation

protocol AccountTypeManagerProtocol: class {

    func getType() -> AccountType
    func setType(_ type: AccountType)
    func resetType()
}

public class AccountTypeManager {

    // MARK: - Public properties

    // MARK: - Private properties

    private let accountTypeKey: String = "accountType"

    private let userDefaults: UserDefaults = .standard

    // MARK: -

    init() { }
}

// MARK: - Private methods

private extension AccountTypeManager {

    func checkTheme() {
        // TODO: - Implement if needed
//        switch getType() {
//        case .guest:
//            Theme.Colors.applyGuestTheme()
//        case .host:
//            Theme.Colors.applyHostTheme()
//        case .general:
//            Theme.Colors.applyDefaultTheme()
//        }
    }
}

// MARK: - AccountTypeManagerProtocol

extension AccountTypeManager: AccountTypeManagerProtocol {

    func getType() -> AccountType {

        let defaultsType: AccountType = .general

        guard let value = userDefaults.value(forKey: accountTypeKey) as? String
        else {
            return defaultsType
        }

        guard let type = AccountType(userDefaultsValue: value)
        else {
            return defaultsType
        }

        return type
    }

    func setType(_ type: AccountType) {

        self.userDefaults.setValue(type.userDefaultsValue, forKey: accountTypeKey)

        checkTheme()
    }

    func resetType() {

        self.userDefaults.removeObject(forKey: accountTypeKey)

        checkTheme()
    }
}

private extension AccountType {

    typealias UserDefaultsValue = String

    var userDefaultsValue: UserDefaultsValue {
        
        return userKey
    }

    init?(
        userDefaultsValue: UserDefaultsValue
    ) {
        
        for type in Self.allCases {
            
            if userDefaultsValue == type.userDefaultsValue {
                self = type
                return
            }
        }

        return nil
    }
}
