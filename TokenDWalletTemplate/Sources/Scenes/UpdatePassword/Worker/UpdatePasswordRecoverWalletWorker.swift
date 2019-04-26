import Foundation
import TokenDSDK
import TokenDWallet

extension UpdatePassword {
    
    class RecoverWalletWorker: BaseSubmitWorker {
        
        // MARK: - Overridden
        
        override func getExpectedFields() -> [Model.Field] {
            return [
                Model.Field(type: .email, value: nil),
                Model.Field(type: .seed, value: nil),
                Model.Field(type: .newPassword, value: nil),
                Model.Field(type: .confirmPassword, value: nil)
            ]
        }
        
        // MARK: - Private
        
        private func getEmail(fields: [Model.Field]) -> String? {
            return self.fieldValueForType(fields: fields, fieldType: .email)
        }
        
        private func getSeed(fields: [Model.Field]) -> String? {
            return self.fieldValueForType(fields: fields, fieldType: .seed)
        }
        
        private func getNewPassword(fields: [Model.Field]) -> String? {
            return self.fieldValueForType(fields: fields, fieldType: .newPassword)
        }
        
        private func getConfirmPassword(fields: [Model.Field]) -> String? {
            return self.fieldValueForType(fields: fields, fieldType: .confirmPassword)
        }
        
        private func buildRecoveryRequest(
            email: String,
            seed: String,
            newPassword: String,
            networkInfo: NetworkInfoModel,
            stopLoading: @escaping () -> Void,
            completion: @escaping (_ result: UpdatePasswordSubmitWorkerProtocol.Result) -> Void
            ) {
            
            let onSignRequest = JSONAPI.RequestSignerBlockCaller.getUnsafeSignRequestBlock()
            
            _ = self.updateRequestBuilder.buildRecoveryWalletRequest(
                for: email,
                recoverySeedBase32Check: seed,
                newPassword: newPassword,
                onSignRequest: onSignRequest,
                networkInfo: networkInfo,
                completion: { [weak self] (result) in
                    
                    switch result {
                        
                    case .failure(let error):
                        stopLoading()
                        completion(.failed(.submitError(error)))
                        
                    case .success(let components):
                        
                        self?.recoverWallet(
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
        
        private func recoverWallet(
            email: String,
            walletId: String,
            signingPassword: String,
            walletKDF: WalletKDFParams,
            walletInfo: WalletInfoModel,
            requestSigner: JSONAPI.RequestSignerProtocol,
            sendDate: Date,
            stopLoading: @escaping () -> Void,
            completion: @escaping (_ result: UpdatePasswordSubmitWorkerProtocol.Result) -> Void
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

extension UpdatePassword.RecoverWalletWorker: UpdatePassword.SubmitPasswordHandler {
    func submitFields(
        _ fields: [UpdatePassword.Model.Field],
        startLoading: @escaping () -> Void,
        stopLoading: @escaping () -> Void,
        completion: @escaping (_ result: UpdatePasswordSubmitWorkerProtocol.Result) -> Void
        ) {
        
        guard let email = self.getEmail(fields: fields), email.count > 0 else {
            completion(.failed(.emptyField(.email)))
            return
        }
        
        guard let seed = self.getSeed(fields: fields), seed.count > 0 else {
            completion(.failed(.emptyField(.seed)))
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
                self?.buildRecoveryRequest(
                    email: email,
                    seed: seed,
                    newPassword: newPassword,
                    networkInfo: info,
                    stopLoading: stopLoading,
                    completion: completion
                )
            }
        })
    }
}
