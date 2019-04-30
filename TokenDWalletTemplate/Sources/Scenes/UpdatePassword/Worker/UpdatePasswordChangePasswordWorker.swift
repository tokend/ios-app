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
            networkInfoFetcher: NetworkInfoFetcher,
            updateRequestBuilder: UpdatePasswordRequestBuilderProtocol,
            passwordValidator: PasswordValidatorProtocol
            ) {
            
            self.userDataProvider = userDataProvider
            
            super.init(
                keyserverApi: keyserverApi,
                keychainManager: keychainManager,
                userDataManager: userDataManager,
                networkInfoFetcher: networkInfoFetcher,
                updateRequestBuilder: updateRequestBuilder,
                passwordValidator: passwordValidator
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
            let onSignRequest = JSONAPI.RequestSignerBlockCaller.getUnsafeSignRequestBlock()
            
            _ = self.updateRequestBuilder.buildChangePasswordRequest(
                for: email,
                oldPassword: oldPassword,
                newPassword: newPassword,
                onSignRequest: onSignRequest,
                networkInfo: networkInfo,
                completion: { [weak self] (result) in
                    switch result {
                        
                    case .failure(let error):
                        stopLoading()
                        completion(.failed(.submitError(error)))
                        
                    case .success(let components):
                        
                        self?.changePassword(
                            email: components.email,
                            walletId: components.walletId,
                            signingPassword: components.signingPassword,
                            walletKDF: components.walletKDF,
                            walletInfo: components.walletInfo,
                            requestSigner: components.requestSigner,
                            sendDate: Date(),
                            stopLoading: stopLoading,
                            completion: completion
                        )
                    }
            })
        }
        
        private func changePassword(
            email: String,
            walletId: String,
            signingPassword: String,
            walletKDF: WalletKDFParams,
            walletInfo: WalletInfoModel,
            requestSigner: JSONAPI.RequestSignerProtocol,
            sendDate: Date,
            stopLoading: @escaping () -> Void,
            completion: @escaping (UpdatePasswordSubmitResult) -> Void
            ) {
            
            _ = self.keyserverApi.performUpdatePasswordRequest(
                email: email,
                walletId: walletId,
                signingPassword: signingPassword,
                walletKDF: walletKDF,
                walletInfo: walletInfo,
                requestSigner: requestSigner,
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
        
        let passwordValidationResult = self.passwordValidator.validate(password: newPassword)
        switch passwordValidationResult {
            
        case .error(let message):
            completion(.failed(.passwordInvalid(message)))
            return
            
        default:
            break
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
