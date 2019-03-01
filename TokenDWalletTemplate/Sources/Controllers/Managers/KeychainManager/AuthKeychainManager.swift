import Foundation
import DLCryptoKit
import SwiftKeychainWrapper

class AuthKeychainManager {
    
    // MARK: - Private properties
    
    private var keyData: ECDSA.KeyData?
    private let keychainWrapper: KeychainWrapper = KeychainWrapper.standard
    
    // MARK: -
    
    private func getAllAccounts() -> [String]? {
        guard let accountsData = self.getOpaqueData(key: .accounts) else {
            return nil
        }
        let accountsModel = try? JSONDecoder().decode(KeychainAccountsModel.self, from: accountsData)
        
        let accounts = accountsModel?.getAccounts()
        
        return accounts
    }
    
    private func saveAccounts(_ accounts: [String]) -> Bool {
        guard let encodedAccounts = KeychainAccountsModel.encodeAccounts(accounts) else {
            return false
        }
        
        let keychainAccountsModel = KeychainAccountsModel(
            version: encodedAccounts.version,
            encodedAccounts: encodedAccounts.encodedAccounts
        )
        
        guard let accountsData = try? JSONEncoder().encode(keychainAccountsModel) else {
            return false
        }
        
        return self.saveOpaqueData(accountsData, key: .accounts)
    }
    
    private func keychainKey(account: String, postfix: KeychainKeyPostfix) -> String {
        let keychainKey = "\(account).\(postfix)"
        
        return keychainKey
    }
}

extension AuthKeychainManager: KeychainManagerProtocol {
    
    func getStringValue(key: KeychainSharedStorageKey) -> String? {
        guard let value = self.keychainWrapper.string(forKey: key.rawValue) else {
            return nil
        }
        
        return value
    }
    
    func saveStringValue(_ string: String, key: KeychainSharedStorageKey) -> Bool {
        return self.keychainWrapper.set(string, forKey: key.rawValue)
    }
    
    func getOpaqueData(key: KeychainSharedStorageKey) -> Data? {
        guard let value = self.keychainWrapper.data(forKey: key.rawValue) else {
            return nil
        }
        
        return value
    }
    
    func saveOpaqueData(_ data: Data, key: KeychainSharedStorageKey) -> Bool {
        return self.keychainWrapper.set(data, forKey: key.rawValue)
    }
    
    func removeValue(key: KeychainSharedStorageKey) -> Bool {
        return self.keychainWrapper.removeObject(forKey: key.rawValue)
    }
    
    // User data
    
    func hasKeyDataForMainAccount() -> Bool {
        let mainAccount = self.getMainAccount()
        let keyData = self.keyData
        
        if mainAccount == nil || keyData == nil {
            return false
        }
        return true
    }
    
    func saveAccount(_ account: String) -> Bool {
        var allAccounts: [String]
        if let accounts = self.getAllAccounts() {
            allAccounts = accounts
        } else {
            allAccounts = []
        }
        
        if allAccounts.contains(account) {
            return true
        } else {
            allAccounts.append(account)
            
            return self.saveAccounts(allAccounts)
        }
    }
    
    func removeAccount(_ account: String) -> Bool {
        var allAccounts: [String]
        if let accounts = self.getAllAccounts() {
            allAccounts = accounts
        } else {
            allAccounts = []
        }
        
        allAccounts.remove(object: account)
        
        return self.saveAccounts(allAccounts)
    }
    
    func getMainAccount() -> String? {
        return self.getAllAccounts()?.first
    }
    
    func getKeyData(account: String) -> ECDSA.KeyData? {
        guard let mainAccount = self.getMainAccount(),
            account == mainAccount else {
                return nil
        }
        return self.keyData
    }
    
    func saveKeyData(_ keyData: ECDSA.KeyData, account: String) -> Bool {
        guard let mainAccount = self.getMainAccount(),
            account == mainAccount else {
                return false
        }
        
        self.keyData = keyData
        return true
    }
    
    func removeKeyData(account: String) -> Bool {
        guard let mainAccount = self.getMainAccount(),
            account == mainAccount else {
                return false
        }
        
        self.keyData = nil
        return true
    }
    
    func validateDerivedKeyData(_ keyData: ECDSA.KeyData, account: String) -> Bool {
        guard let mainAccount = self.getMainAccount(),
            let storedKeyData = self.keyData,
            mainAccount == account else {
                return false
        }
        
        return storedKeyData.getSeedData() == keyData.getSeedData()
    }
    
    func hasOpaqueData(account: String, keyPostfix: KeychainKeyPostfix) -> Bool {
        let keychainKey = self.keychainKey(account: account, postfix: keyPostfix)
        
        return self.keychainWrapper.hasValue(forKey: keychainKey)
    }
    
    func getOpaqueData(account: String, keyPostfix: KeychainKeyPostfix) -> Data? {
        let keychainKey = self.keychainKey(account: account, postfix: keyPostfix)
        
        return self.keychainWrapper.data(forKey: keychainKey)
    }
    
    func saveOpaqueData(_ data: Data, account: String, keyPostfix: KeychainKeyPostfix) -> Bool {
        let keychainKey = self.keychainKey(account: account, postfix: keyPostfix)
        
        return self.keychainWrapper.set(data, forKey: keychainKey)
    }
    
    func removeOpaqueData(account: String, keyPostfix: KeychainKeyPostfix) -> Bool {
        let keychainKey = self.keychainKey(account: account, postfix: keyPostfix)
        
        return self.keychainWrapper.removeObject(forKey: keychainKey)
    }
    
    func clearAllData() {
        KeychainWrapper.wipeKeychain()
    }
}
