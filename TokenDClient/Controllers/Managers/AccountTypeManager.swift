import Foundation
import RxSwift
import RxCocoa

protocol AccountTypeManagerProtocol: AnyObject {

    var accountType: AccountType { get }
    
    func setType(_ type: AccountType)
    func observeAccountType() -> Observable<AccountType>
    func resetType()
}

public class AccountTypeManager {

    // MARK: - Private properties

    private let accountTypeKey: String = "accountType"

    private let userDefaults: UserDefaults = .standard
    private lazy var accountTypeBehaviorRelay: BehaviorRelay<AccountType> = .init(value: getType())
    
    // MARK: - Public properties
    
    var accountType: AccountType {
        accountTypeBehaviorRelay.value
    }

    // MARK: -

    init() { }
}

// MARK: - Private methods

private extension AccountTypeManager {
    
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
}

// MARK: - AccountTypeManagerProtocol

extension AccountTypeManager: AccountTypeManagerProtocol {

    func setType(_ type: AccountType) {

        self.userDefaults.setValue(type.userDefaultsValue, forKey: accountTypeKey)
        accountTypeBehaviorRelay.accept(type)
    }
    
    func observeAccountType() -> Observable<AccountType> {
        
        accountTypeBehaviorRelay.asObservable()
    }

    func resetType() {

        self.userDefaults.removeObject(forKey: accountTypeKey)
        accountTypeBehaviorRelay.accept(getType())
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
