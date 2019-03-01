import Foundation
import TokenDSDK
import DLCryptoKit

enum RegisterSceneSignUpBuilderBuildResult {
    
    struct BuildError: Swift.Error, LocalizedError {
        
        let createWalletError: SignUpRequestBuilder.Result.CreateWalletError
        
        // MARK: - Swift.Error
        
        public var errorDescription: String? {
            switch self.createWalletError {
                
            case .failedToGenerateKeyPair:
                return Localized(.failed_to_generate_key_pair)
                
            case .failedToGeneratePasswordFactorKeyPair:
                return Localized(.failed_to_generate_password_factor_key_pair)
                
            case .failedToGenerateRecoveryKeyPair:
                return Localized(.failed_to_generate_recovery_key_pair)
                
            case .registrationInfoError(let error):
                return error.localizedDescription
                
            case .walletKDFError(let error):
                return error.localizedDescription
            }
        }

    }
    
    case failure(BuildError)
    case success(
        email: String,
        recoveryKey: ECDSA.KeyData,
        walletInfo: WalletInfoModel,
        walletKDF: WalletKDFParams
    )
}

protocol RegisterSceneSignUpBuilderProtocol {
    func buildSignUpRequest(
        for email: String,
        password: String,
        completion: @escaping (RegisterSceneSignUpBuilderBuildResult) -> Void
    )
}

extension SignUpRequestBuilder: RegisterSceneSignUpBuilderProtocol {
    
    func buildSignUpRequest(
        for email: String,
        password: String,
        completion: @escaping (RegisterSceneSignUpBuilderBuildResult) -> Void
        ) {
        
        self.buildSignUpRequest(
            email: email,
            password: password,
            completion: { (result) in
                switch result {
                    
                case .failure(let error):
                    let buildError = RegisterSceneSignUpBuilderBuildResult.BuildError(createWalletError: error)
                    completion(.failure(buildError))
                    
                case .success(let email, let recoveryKey, let walletInfo, let walletKDF):
                    completion(.success(
                        email: email,
                        recoveryKey: recoveryKey,
                        walletInfo: walletInfo,
                        walletKDF: walletKDF
                        )
                    )
                }
        })
    }
}
