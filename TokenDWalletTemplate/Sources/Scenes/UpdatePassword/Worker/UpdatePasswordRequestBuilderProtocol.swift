import Foundation
import TokenDSDK
import DLCryptoKit
import TokenDWallet

enum UpdatePasswordRequestBuilderBuildResult {
    
    struct BuildError: Swift.Error, LocalizedError {
        
        let updateError: UpdatePasswordRequestBuilder.Result.UpdateError
        
        // MARK: - Swift.Error
        
        public var errorDescription: String? {
            switch self.updateError {
                
            case .cannotDecodeOriginalAccountIdData:
                return Localized(.cannot_decode_original_account_id_data)
                
            case .cannotDeriveEncodedWalletId:
                return Localized(.cannot_derive_encoded_wallet_id)
                
            case .cannotDeriveOldKeyFrom(let error):
                return error.localizedDescription
                
            case .cannotDeriveRecoveryKeyFromSeed(let error):
                return error.localizedDescription
                
            case .corruptedKeychainData:
                return Localized(.corrupted_keychain_data)
                
            case .newKeyGenerationFailed:
                return Localized(.failed_to_generate_new_key_pair)
                
            case .failedToRetriveSigners(let errors):
                return errors.localizedDescription
                
            case .other(let error):
                return error.localizedDescription
                
            case .walletDataError(let error):
                return error.localizedDescription
                
            case .walletInfoBuilderUpdatePasswordError(let error):
                return error.localizedDescription
                
            case .walletKDFError(let error):
                return error.localizedDescription
                
            case .wrongOldPassword:
                return Localized(.wrong_old_password)
                
            case .emptySignersDocument:
                return Localized(.empty_signers_data)
            }
        }
    }
    
    case failure(BuildError)
    case success(UpdatePasswordRequestBuilder.Result.UpdatePasswordRequestComponents)
}

protocol UpdatePasswordRequestBuilderProtocol {
    
    func buildChangePasswordRequest(
        for email: String,
        oldPassword: String,
        newPassword: String,
        onSignRequest: @escaping JSONAPI.SignRequestBlock,
        networkInfo: NetworkInfoModel,
        completion: @escaping (UpdatePasswordRequestBuilderBuildResult) -> Void
        ) -> Cancelable
    
    func buildRecoveryWalletRequest(
        for email: String,
        recoverySeedBase32Check: String,
        newPassword: String,
        onSignRequest: @escaping JSONAPI.SignRequestBlock,
        networkInfo: NetworkInfoModel,
        completion: @escaping (UpdatePasswordRequestBuilderBuildResult) -> Void
        ) -> Cancelable
}

extension UpdatePasswordRequestBuilder: UpdatePasswordRequestBuilderProtocol {
    
    func buildChangePasswordRequest(
        for email: String,
        oldPassword: String,
        newPassword: String,
        onSignRequest: @escaping JSONAPI.SignRequestBlock,
        networkInfo: NetworkInfoModel,
        completion: @escaping (UpdatePasswordRequestBuilderBuildResult) -> Void
        ) -> Cancelable {
        
        return self.buildChangePasswordRequest(
            email: email,
            oldPassword: oldPassword,
            newPassword: newPassword,
            onSignRequest: onSignRequest,
            networkInfo: networkInfo,
            completion: { (result) in
                switch result {
                    
                case .failure(let error):
                    let buildError = UpdatePasswordRequestBuilderBuildResult.BuildError(updateError: error)
                    completion(.failure(buildError))
                    
                case .success(let components):
                    completion(.success(components))
                }
        })
    }
    
    func buildRecoveryWalletRequest(
        for email: String,
        recoverySeedBase32Check: String,
        newPassword: String,
        onSignRequest: @escaping JSONAPI.SignRequestBlock,
        networkInfo: NetworkInfoModel,
        completion: @escaping (UpdatePasswordRequestBuilderBuildResult) -> Void
        ) -> Cancelable {
        
        return self.buildRecoveryWalletRequest(
            email: email,
            recoverySeedBase32Check: recoverySeedBase32Check,
            newPassword: newPassword,
            onSignRequest: onSignRequest,
            networkInfo: networkInfo,
            completion: { (result) in
                switch result {
                    
                case .failure(let error):
                    let buildError = UpdatePasswordRequestBuilderBuildResult.BuildError(updateError: error)
                    completion(.failure(buildError))
                    
                case .success(let components):
                    completion(.success(components))
                }
        })
    }
}
