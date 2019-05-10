import Foundation

enum RegisterSceneSignError {
    case emailAlreadyTaken
    case emailShouldBeVerified(walletId: String)
    case failedToSaveAccount
    case failedToSaveNetwork
    case otherError(Error)
    case tfaFailed
    case wrongEmail
    case wrongPassword
}

enum RegisterSceneServerInfoQRCodeParseResult {
    case failure
    case success
}

enum RegisterSceneSignInResult {
    typealias SignError = RegisterSceneSignError
    
    case failed(SignError)
    case succeeded(account: String)
}

protocol RegisterSceneSignInWorkerProtocol {
    typealias SignInResult = RegisterSceneSignInResult
    
    func performSignInRequest(
        email: String,
        password: String,
        completion: @escaping (_ result: SignInResult) -> Void
    )
    
    typealias QRCodeParseResult = RegisterSceneServerInfoQRCodeParseResult
    
    func getServerInfoTitle() -> String
    func handleServerInfoQRScannedString(_ value: String) -> QRCodeParseResult
}

enum RegisterSceneSignUpResult {
    typealias SignError = RegisterSceneSignError
    
    case failed(SignError)
    case succeeded(model: RegisterScene.TokenDRegisterWorker.SignUpModel)
}

protocol RegisterSceneSignUpWorkerProtocol {
    typealias SignUpResult = RegisterSceneSignUpResult
    
    func performSignUpRequest(
        email: String,
        password: String,
        completion: @escaping (_ result: SignUpResult) -> Void
    )
    
    typealias QRCodeParseResult = RegisterSceneServerInfoQRCodeParseResult
    
    func getServerInfoTitle() -> String
    func handleServerInfoQRScannedString(_ value: String) -> QRCodeParseResult
}

protocol RegisterSceneSignOutWorkerProtocol {
    func performSignOut(completion: @escaping () -> Void)
}

extension RegisterScene {
    typealias SignRequestError = RegisterSceneSignError
}
