import Foundation
import TokenDSDK
import TokenDWallet

extension UpdatePassword {
    
    class ChangePasswordWorker: BaseSubmitWorker {
        
        // MARK: - Public properties
        
        let userDataProvider: UserDataProviderProtocol
        
        // MARK: -
        
        required init(
            keyserverApi: KeyServerApi,
            keychainManager: KeychainManagerProtocol,
            userDataManager: UserDataManagerProtocol,
            userDataProvider: UserDataProviderProtocol,
            networkInfoFetcher: NetworkInfoFetcher
            ) {
            
            self.userDataProvider = userDataProvider
            
            super.init(
                keyserverApi: keyserverApi,
                keychainManager: keychainManager,
                userDataManager: userDataManager,
                networkInfoFetcher: networkInfoFetcher
            )
        }
        
        // MARK: - Overridden
        
        override func getExpectedFields() -> [Model.Field] {
            return [
                Model.Field(type: .oldPassword, value: nil),
                Model.Field(type: .newPassword, value: nil),
                Model.Field(type: .confirmPassword, value: nil)
            ]
        }
        
        // MARK: - Private
        
        private func getOldPassword(fields: [Model.Field]) -> String? {
            return self.fieldValueForType(fields: fields, fieldType: .oldPassword)
        }
        
        private func getNewPassword(fields: [Model.Field]) -> String? {
            return self.fieldValueForType(fields: fields, fieldType: .newPassword)
        }
        
        private func getConfirmPassword(fields: [Model.Field]) -> String? {
            return self.fieldValueForType(fields: fields, fieldType: .confirmPassword)
        }
        
        private func submitChangePassword(
            oldPassword: String,
            newPassword: String,
            networkInfo: NetworkInfoModel,
            stopLoading: @escaping () -> Void,
            completion: @escaping (_ result: UpdatePasswordSubmitWorkerProtocol.Result) -> Void
            ) {
            
            let email = self.userDataProvider.userEmail
            
            _ = self.keyserverApi.changeWalletPassword(
                email: email,
                oldPassword: oldPassword,
                newPassword: newPassword,
                networkInfo: networkInfo,
                completion: { (result) in
                    stopLoading()
                    
                    switch result {
                        
                    case .failed(let error):
                        completion(.failed(.submitError(error)))
                        
                    case .succeeded:
                        completion(.succeeded)
                    }
            })
        }
    }
}

extension UpdatePassword.ChangePasswordWorker: UpdatePassword.SubmitPasswordHandler {
    func submitFields(
        _ fields: [UpdatePassword.Model.Field],
        startLoading: @escaping () -> Void,
        stopLoading: @escaping () -> Void,
        completion: @escaping (_ result: UpdatePasswordSubmitWorkerProtocol.Result) -> Void
        ) {
        
        guard let oldPassword = self.getOldPassword(fields: fields), oldPassword.count > 0 else {
            completion(.failed(.emptyField(.oldPassword)))
            return
        }
        
        guard let newPassword = self.getNewPassword(fields: fields), newPassword.count > 0 else {
            completion(.failed(.emptyField(.newPassword)))
            return
        }
        
        guard let confirmPassword = self.getConfirmPassword(fields: fields), confirmPassword.count > 0 else {
            completion(.failed(.emptyField(.confirmPassword)))
            return
        }
        
        guard newPassword == confirmPassword else {
            completion(.failed(.passwordsDontMatch))
            return
        }
        
        startLoading()
        self.networkInfoFetcher.fetchNetworkInfo({ [weak self] (result) in
            switch result {
                
            case .failed(let error):
                stopLoading()
                completion(.failed(.networkInfoFetchFailed(error)))
                
            case .succeeded(let info):
                self?.submitChangePassword(
                    oldPassword: oldPassword,
                    newPassword: newPassword,
                    networkInfo: info,
                    stopLoading: stopLoading,
                    completion: completion
                )
            }
        })
    }
}
