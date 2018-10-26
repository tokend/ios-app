import Foundation
import TokenDSDK
import DLCryptoKit

protocol FlowControllerProtocol {
    
    var currentFlowController: FlowControllerProtocol? { get set }
    
    // MARK: - App life cycle
    
    func applicationDidEnterBackground()
    func applicationWillEnterForeground()
    func applicationDidBecomeActive()
    func applicationWillResignActive()
    
    func showBlockingProgress()
    func hideBlockingProgress()
    
    // MARK: - TokenD SDK
    
    func performTFA(tfaInput: ApiCallbacks.TFAInput, cancel: @escaping () -> Void)
    
    // QRCodeReader
    
    func runQRCodeReaderFlow(
        presentingViewController: UIViewController,
        handler: @escaping QRCodeReaderFlowController.QRCodeReaderCompletion
    )
}

class FlowControllerStack {
    
    // MARK: - APIs
    
    var api: TokenDSDK.API
    var verifyApi: TokenDSDK.TFAVerifyApi
    var keyServerApi: TokenDSDK.KeyServerApi
    var usersApi: TokenDSDK.UsersApi
    
    var apiConfigurationModel: APIConfigurationModel
    var tfaDataProvider: TFADataProviderProtocol
    var networkInfoFetcher: NetworkInfoRepo
    var settingsManager: SettingsManagerProtocol
    
    // MARK: -
    
    init(
        apiConfigurationModel: APIConfigurationModel,
        tfaDataProvider: TFADataProviderProtocol,
        userAgent: String,
        apiCallbacks: ApiCallbacks,
        keyDataProvider: RequestSignKeyDataProviderProtocol,
        settingsManager: SettingsManagerProtocol
        ) {
        
        let apiConfiguration = ApiConfiguration(
            urlString: apiConfigurationModel.apiEndpoint,
            userAgent: userAgent
        )
        
        let api = TokenDSDK.API(
            configuration: apiConfiguration,
            callbacks: apiCallbacks,
            keyDataProvider: keyDataProvider
        )
        
        let requestSigner = RequestSigner(keyDataProvider: keyDataProvider)
        
        let verifyApi = TokenDSDK.TFAVerifyApi(
            apiConfiguration: apiConfiguration,
            requestSigner: requestSigner
        )
        
        let keyServerApi = KeyServerApi(
            apiConfiguration: apiConfiguration,
            callbacks: apiCallbacks,
            verifyApi: verifyApi,
            requestSigner: requestSigner
        )
        
        let usersApi = UsersApi(
            apiConfiguration: apiConfiguration,
            requestSigner: requestSigner
        )
        
        let networkInfoRepo = NetworkInfoRepo(api: api.generalApi)
        
        self.api = api
        self.verifyApi = verifyApi
        self.keyServerApi = keyServerApi
        self.usersApi = usersApi
        self.apiConfigurationModel = apiConfigurationModel
        self.tfaDataProvider = tfaDataProvider
        self.networkInfoFetcher = networkInfoRepo
        self.settingsManager = settingsManager
    }
    
    func updateWith(
        apiConfigurationModel: APIConfigurationModel,
        tfaDataProvider: TFADataProviderProtocol,
        userAgent: String,
        apiCallbacks: ApiCallbacks,
        keyDataProvider: RequestSignKeyDataProviderProtocol,
        settingsManager: SettingsManagerProtocol
        ) {
        
        let apiConfiguration = ApiConfiguration(
            urlString: apiConfigurationModel.apiEndpoint,
            userAgent: userAgent
        )
        
        let api = TokenDSDK.API(
            configuration: apiConfiguration,
            callbacks: apiCallbacks,
            keyDataProvider: keyDataProvider
        )
        
        let requestSigner = RequestSigner(keyDataProvider: keyDataProvider)
        
        let verifyApi = TokenDSDK.TFAVerifyApi(
            apiConfiguration: apiConfiguration,
            requestSigner: requestSigner
        )
        
        let keyServerApi = KeyServerApi(
            apiConfiguration: apiConfiguration,
            callbacks: apiCallbacks,
            verifyApi: verifyApi,
            requestSigner: requestSigner
        )
        
        let usersApi = UsersApi(
            apiConfiguration: apiConfiguration,
            requestSigner: requestSigner
        )
        
        let networkInfoRepo = NetworkInfoRepo(api: api.generalApi)
        
        self.api = api
        self.verifyApi = verifyApi
        self.keyServerApi = keyServerApi
        self.usersApi = usersApi
        self.apiConfigurationModel = apiConfigurationModel
        self.tfaDataProvider = tfaDataProvider
        self.networkInfoFetcher = networkInfoRepo
        self.settingsManager = settingsManager
    }
}

class BaseFlowController: FlowControllerProtocol {
    
    var currentFlowController: FlowControllerProtocol?
    
    // MARK: - Public properties
    
    let appController: AppControllerProtocol
    let flowControllerStack: FlowControllerStack
    let rootNavigation: RootNavigationProtocol
    
    // MARK: - Private properties
    
    private var inputTFAText: String = ""
    
    // MARK: -
    
    init(
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        rootNavigation: RootNavigationProtocol
        ) {
        
        self.appController = appController
        self.flowControllerStack = flowControllerStack
        self.rootNavigation = rootNavigation
    }
    
    // MARK: - FlowControllerProtocol
    
    func applicationDidEnterBackground() {
        self.currentFlowController?.applicationDidEnterBackground()
    }
    
    func applicationWillEnterForeground() {
        self.currentFlowController?.applicationWillEnterForeground()
    }
    
    func applicationDidBecomeActive() {
        self.currentFlowController?.applicationDidBecomeActive()
    }
    
    func applicationWillResignActive() {
        self.currentFlowController?.applicationWillResignActive()
    }
    
    func showBlockingProgress() {
        
    }
    
    func hideBlockingProgress() {
        
    }
    
    func performTFA(tfaInput: ApiCallbacks.TFAInput, cancel: @escaping () -> Void) {
        self.onDefaultTFA(tfaInput: tfaInput, cancel: cancel)
    }
    
    func runQRCodeReaderFlow(
        presentingViewController: UIViewController,
        handler: @escaping QRCodeReaderFlowController.QRCodeReaderCompletion
        ) {
        
        let flow = QRCodeReaderFlowController(
            appController: self.appController,
            flowControllerStack: self.flowControllerStack,
            rootNavigation: self.rootNavigation,
            presentingViewController: presentingViewController,
            handler: { [weak self] result in
                self?.currentFlowController = nil
                handler(result)
        })
        self.currentFlowController = flow
        flow.run()
    }
    
    // MARK: - Private
    
    private func onDefaultTFA(tfaInput: ApiCallbacks.TFAInput, cancel: @escaping () -> Void) {
        let alertTitle: String
        let alertMessage: String?
        switch tfaInput {
            
        case .password:
            alertTitle = "Input Password"
            alertMessage = nil
            
        case .code(let type, _):
            switch type {
                
            case .email:
                alertTitle = "Input 2FA Code"
                alertMessage = "Input code sent to your email"
                
            case .other(let source):
                alertTitle = "Input 2FA Code"
                alertMessage = "Source: \(source)"
                
            case .totp:
                alertTitle = "Input 2FA Code"
                alertMessage = "Input code from Google Authenticator or similar app"
            }
        }
        
        self.presentTextField(title: alertTitle, message: alertMessage, completion: { [weak self] (text) in
            switch tfaInput {
                
            case .password(let tokenSignData, let inputCallback):
                guard
                    let userEmail = self?.flowControllerStack.tfaDataProvider.getUserEmail(),
                    let kdfParams = self?.flowControllerStack.tfaDataProvider.getKdfParams()
                    else {
                        cancel()
                        return
                }
                
                self?.processInput(
                    email: userEmail,
                    password: text,
                    kdfParams: kdfParams,
                    tokenSignData: tokenSignData,
                    inputCallback: inputCallback,
                    cancel: cancel
                )
                
            case .code(_, let inputCallback):
                inputCallback(text)
            }
            }, cancel: {
                cancel()
        })
    }
    
    private func processInput(
        email: String,
        password: String,
        kdfParams: KDFParams,
        tokenSignData: ApiCallbacks.TokenSignData,
        inputCallback: @escaping (_ signedToken: String) -> Void,
        cancel: @escaping () -> Void
        ) {
        
        guard
            let signedToken = self.getSignedTokenForPassword(
                password,
                walletId: tokenSignData.walletId,
                keychainData: tokenSignData.keychainData,
                email: email,
                token: tokenSignData.token,
                factorId: tokenSignData.factorId,
                walletKDF: WalletKDFParams(
                    kdfParams: kdfParams,
                    salt: tokenSignData.salt
                )
            ) else {
                print("Unable to sign TFA token with password")
                cancel()
                return
        }
        inputCallback(signedToken)
    }
    
    public func getSignedTokenForPassword(
        _ password: String,
        walletId: String,
        keychainData: Data,
        email: String,
        token: String,
        factorId: Int,
        walletKDF: WalletKDFParams
        ) -> String? {
        
        guard
            let keyPair = try? KeyPairBuilder.getKeyPair(
                forEmail: email,
                password: password,
                keychainData: keychainData,
                walletKDF: walletKDF
            ) else {
                print("Unable to get keychainData or create key pair")
                return nil
        }
        
        guard let data = token.data(using: .utf8) else {
            print("Unable to encode token to data")
            return nil
        }
        
        guard let signedToken = try? ECDSA.signED25519(data: data, keyData: keyPair).base64EncodedString() else {
            print("Unable to sign token data")
            return nil
        }
        
        return signedToken
    }
    
    private func presentTextField(
        title: String,
        message: String? = nil,
        completion: @escaping (_ text: String) -> Void,
        cancel: @escaping () -> Void
        ) {
        
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        alert.addTextField { (tf) in
            tf.addTarget(self, action: #selector(self.tfaTextFieldEditingChanged), for: .editingChanged)
        }
        
        alert.addAction(UIAlertAction(
            title: "Done",
            style: .default,
            handler: { _ in
                completion(self.inputTFAText)
        }))
        
        alert.addAction(UIAlertAction(
            title: "Cancel TFA",
            style: .cancel,
            handler: { _ in
                cancel()
        }))
        
        self.rootNavigation.presentAlert(alert, animated: true, completion: nil)
    }
    
    @objc private func tfaTextFieldEditingChanged(_ tf: UITextField) {
        self.inputTFAText = tf.text ?? ""
    }
}
