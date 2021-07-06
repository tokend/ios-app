import Foundation
import TokenDSDK
import TokenDWallet
import DLCryptoKit
import SwiftKeychainWrapper

public enum KeychainKeyPostfix: String {
    
    case keyDataSeed
    case walletData
}

public enum KeychainSharedStorageKey: String {
    
    case accounts
}

public protocol KeychainManagerProtocol {
    
    // Shared storage
    
    func getStringValue(key: KeychainSharedStorageKey) -> String?
    func saveStringValue(_ string: String, key: KeychainSharedStorageKey) -> Bool
    
    func getOpaqueData(key: KeychainSharedStorageKey) -> Data?
    func saveOpaqueData(_ data: Data, key: KeychainSharedStorageKey) -> Bool
    
    func removeValue(key: KeychainSharedStorageKey) -> Bool
    
    // User data
    
    func hasKeyDataForMainAccount() -> Bool
    
    func saveAccount(_ account: String) -> Bool
    func removeAccount(_ account: String) -> Bool
    func getMainAccount() -> String?
    
    func getKeyData(account: String) -> [ECDSA.KeyData]?
    func saveKeyData(_ keyData: [ECDSA.KeyData], account: String) -> Bool
    func removeKeyData(account: String) -> Bool
    func validateDerivedKeyData(_ keyData: [ECDSA.KeyData], account: String) -> Bool
    
    func hasOpaqueData(account: String, keyPostfix: KeychainKeyPostfix) -> Bool
    func getOpaqueData(account: String, keyPostfix: KeychainKeyPostfix) -> Data?
    func saveOpaqueData(_ data: Data, account: String, keyPostfix: KeychainKeyPostfix) -> Bool
    func removeOpaqueData(account: String, keyPostfix: KeychainKeyPostfix) -> Bool
    
    func clearAllData()
}

public class KeychainManager {
    
    // MARK: - Private properties
    
    private let keychainWrapper: KeychainWrapper = KeychainWrapper.standard
    private let jsonDecoder: JSONDecoder = .init()
    private let jsonEncoder: JSONEncoder = .init()
    
    // MARK: - Private
    
    private func checkAccountSaved(_ account: String) -> Bool {
        return self.saveAccount(account)
    }
    
    private func getAllAccounts() -> [String]? {
        guard let accountsData = self.getOpaqueData(key: .accounts) else {
            return nil
        }
        let accountsModel = try? jsonDecoder.decode(KeychainAccountsModel.self, from: accountsData)
        
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
        
        guard let accountsData = try? jsonEncoder.encode(keychainAccountsModel) else {
            return false
        }
        
        return self.saveOpaqueData(accountsData, key: .accounts)
    }
    
    func hasKeyData(account: String) -> Bool {
        let keychainKey = self.keychainKey(account: account, postfix: KeychainKeyPostfix.keyDataSeed)
        
        return self.keychainWrapper.hasValue(forKey: keychainKey)
    }
    
    private func keychainKey(account: String, postfix: KeychainKeyPostfix) -> String {
        let keychainKey = "\(account).\(postfix)"
        
        return keychainKey
    }
}

// MARK: - KeychainManagerProtocol

extension KeychainManager: KeychainManagerProtocol {
    
    // Shared storage
    
    public func getStringValue(key: KeychainSharedStorageKey) -> String? {
        guard let value = self.keychainWrapper.string(forKey: key.rawValue) else {
            return nil
        }
        
        return value
    }
    
    public func saveStringValue(_ string: String, key: KeychainSharedStorageKey) -> Bool {
        return self.keychainWrapper.set(string, forKey: key.rawValue)
    }
    
    public func getOpaqueData(key: KeychainSharedStorageKey) -> Data? {
        guard let value = self.keychainWrapper.data(forKey: key.rawValue) else {
            return nil
        }
        
        return value
    }
    
    public func saveOpaqueData(_ data: Data, key: KeychainSharedStorageKey) -> Bool {
        return self.keychainWrapper.set(data, forKey: key.rawValue)
    }
    
    public func removeValue(key: KeychainSharedStorageKey) -> Bool {
        return self.keychainWrapper.removeObject(forKey: key.rawValue)
    }
    
    // User data
    
    public func hasKeyDataForMainAccount() -> Bool {
        guard let mainAccount = self.getMainAccount() else {
            return false
        }
        
        return self.hasKeyData(account: mainAccount)
    }
    
    public func saveAccount(_ account: String) -> Bool {
        var allAccounts: [String]
        if let accounts = self.getAllAccounts() {
            allAccounts = accounts
        } else {
            allAccounts = []
        }
        
        if allAccounts.contains(account) {
            
            // This is a hack added because of `mainAccount` implementation
            // FIXME: - Rebuild `mainAccount` implementation with use of `activeAccount`
            if allAccounts.first == account {
                return true
            } else {
                allAccounts.remove(object: account)
                allAccounts.insert(account, at: 0)
                
                return self.saveAccounts(allAccounts)
            }
        } else {
            allAccounts.insert(account, at: 0)
            
            return self.saveAccounts(allAccounts)
        }
    }
    
    public func removeAccount(_ account: String) -> Bool {
        var allAccounts: [String]
        if let accounts = self.getAllAccounts() {
            allAccounts = accounts
        } else {
            allAccounts = []
        }
        
        allAccounts.remove(object: account)
        
        return self.saveAccounts(allAccounts)
    }
    
    public func getMainAccount() -> String? {
        return self.getAllAccounts()?.first
    }
    
    public func getKeyData(account: String) -> [ECDSA.KeyData]? {
        guard let keyDataData = self.getOpaqueData(account: account, keyPostfix: .keyDataSeed) else {
            return nil
        }
        let keyDataModel = try? jsonDecoder.decode(KeychainKeyDataModel.self, from: keyDataData)

        let keyData = keyDataModel?.getKeyData()

        return keyData
    }
    
    public func saveKeyData(_ keyData: [ECDSA.KeyData], account: String) -> Bool {
        guard self.checkAccountSaved(account) else {
            return false
        }

        guard let encodedKeyData = KeychainKeyDataModel.encodeKeyData(keyData) else {
            return false
        }

        let keychainKeyDataModel = KeychainKeyDataModel(
            version: encodedKeyData.version,
            encodedKeyData: encodedKeyData.encodedKeyData
        )

        guard let keyData = try? jsonEncoder.encode(keychainKeyDataModel) else {
            return false
        }

        return self.saveOpaqueData(keyData, account: account, keyPostfix: .keyDataSeed)
    }
    
    public func removeKeyData(account: String) -> Bool {
        return self.removeOpaqueData(account: account, keyPostfix: .keyDataSeed)
    }
    
    public func validateDerivedKeyData(_ keyData: [ECDSA.KeyData], account: String) -> Bool {
        // TODO: - Decide which key to compare
        guard let savedKey = self.getKeyData(account: account)?.first,
              let key = keyData.first else {
            return false
        }
        
        let savedSeedData = savedKey.getSeedData()
        let seedData = key.getSeedData()
        
        return savedSeedData == seedData
    }
    
    public func hasOpaqueData(account: String, keyPostfix: KeychainKeyPostfix) -> Bool {
        let keychainKey = self.keychainKey(account: account, postfix: keyPostfix)
        
        return self.keychainWrapper.hasValue(forKey: keychainKey)
    }
    
    public func getOpaqueData(account: String, keyPostfix: KeychainKeyPostfix) -> Data? {
        let keychainKey = self.keychainKey(account: account, postfix: keyPostfix)
        
        return self.keychainWrapper.data(forKey: keychainKey)
    }
    
    public func saveOpaqueData(_ data: Data, account: String, keyPostfix: KeychainKeyPostfix) -> Bool {
        let keychainKey = self.keychainKey(account: account, postfix: keyPostfix)
        
        return self.keychainWrapper.set(data, forKey: keychainKey)
    }
    
    public func removeOpaqueData(account: String, keyPostfix: KeychainKeyPostfix) -> Bool {
        let keychainKey = self.keychainKey(account: account, postfix: keyPostfix)
        
        return self.keychainWrapper.removeObject(forKey: keychainKey)
    }
    
    public func clearAllData() {
        KeychainWrapper.wipeKeychain()
    }
}

// MARK: - RequestSignKeyDataProvider

public class RequestSignKeyDataProvider: RequestSignKeyDataProviderProtocol {
    
    // MARK: - Public properties
    
    let keychainManager: KeychainManagerProtocol
    
    // MARK: -
    
    public init(keychainManager: KeychainManagerProtocol) {
        self.keychainManager = keychainManager
    }
    
    // MARK: - RequestSignKeyDataProviderProtocol
    
    public func getPrivateKeyData(completion: @escaping (ECDSA.KeyData?) -> Void) {
        guard let mainAccount = self.keychainManager.getMainAccount() else {
            completion(nil)
            return
        }
        
        let keyData = self.keychainManager.getKeyData(account: mainAccount)
        completion(keyData?.first)
    }
    
    public func getPublicKeyString(completion: @escaping (String?) -> Void) {
        guard let mainAccount = self.keychainManager.getMainAccount() else {
            completion(nil)
            return
        }
        
        let keyData = self.keychainManager.getKeyData(account: mainAccount)
        
        guard let publicKeyData = keyData?.first?.getPublicKeyData() else {
            completion(nil)
            return
        }
        
        let publicKey = Base32Check.encode(version: .accountIdEd25519, data: publicKeyData)
        completion(publicKey)
    }
}
