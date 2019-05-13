import UIKit
import ContactsUI
import DLCryptoKit
import TokenDSDK

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
    
    // Contact Picker
    
    func presentContactEmailPicker(
        completion: @escaping (_ email: String) -> Void,
        presentViewController: @escaping PresentViewControllerClosure
    )
}

class FlowControllerStack {
    
    // MARK: - APIs
    
    var api: TokenDSDK.API
    var apiV3: TokenDSDK.APIv3
    var verifyApi: TokenDSDK.TFAVerifyApi
    var keyServerApi: TokenDSDK.KeyServerApi
    
    var network: NetworkProtocol
    
    var apiConfigurationModel: APIConfigurationModel
    var tfaDataProvider: TFADataProviderProtocol
    var networkInfoFetcher: NetworkInfoRepo
    var settingsManager: SettingsManagerProtocol
    
    // MARK: -
    
    init(
        apiConfigurationModel: APIConfigurationModel,
        tfaDataProvider: TFADataProviderProtocol,
        network: NetworkProtocol,
        networkV3: JSONAPI.NetworkProtocol,
        apiCallbacks: ApiCallbacks,
        apiCallbacksV3: JSONAPI.ApiCallbacks,
        keyDataProvider: RequestSignKeyDataProviderProtocol,
        settingsManager: SettingsManagerProtocol
        ) {
        
        let apiConfiguration = ApiConfiguration(
            urlString: apiConfigurationModel.apiEndpoint
        )
        
        let requestSigner = RequestSigner(keyDataProvider: keyDataProvider)
        let requestSignerV3 = JSONAPI.RequestSigner(keyDataProvider: keyDataProvider)
        
        let api = TokenDSDK.API(
            configuration: apiConfiguration,
            callbacks: apiCallbacks,
            network: network,
            requestSigner: requestSigner
        )
        
        let apiV3 = TokenDSDK.APIv3(
            configuration: apiConfiguration,
            callbacks: apiCallbacksV3,
            network: networkV3,
            requestSigner: requestSignerV3
        )
        
        let verifyApi = TokenDSDK.TFAVerifyApi(
            apiConfiguration: apiConfiguration,
            requestSigner: requestSigner,
            network: network
        )
        
        let keyServerApi = KeyServerApi(
            apiConfiguration: apiConfiguration,
            callbacks: apiCallbacks,
            verifyApi: verifyApi,
            requestSigner: requestSignerV3,
            network: network,
            networkV3: networkV3
        )
        
        let networkInfoRepo = NetworkInfoRepo(api: api.generalApi)
        
        self.api = api
        self.apiV3 = apiV3
        self.verifyApi = verifyApi
        self.keyServerApi = keyServerApi
        self.network = network
        self.apiConfigurationModel = apiConfigurationModel
        self.tfaDataProvider = tfaDataProvider
        self.networkInfoFetcher = networkInfoRepo
        self.settingsManager = settingsManager
    }
    
    func updateWith(
        apiConfigurationModel: APIConfigurationModel,
        tfaDataProvider: TFADataProviderProtocol,
        network: NetworkProtocol,
        networkV3: JSONAPI.NetworkProtocol,
        apiCallbacks: ApiCallbacks,
        apiCallbacksV3: JSONAPI.ApiCallbacks,
        keyDataProvider: RequestSignKeyDataProviderProtocol,
        settingsManager: SettingsManagerProtocol
        ) {
        
        let apiConfiguration = ApiConfiguration(
            urlString: apiConfigurationModel.apiEndpoint
        )
        
        let requestSigner = RequestSigner(keyDataProvider: keyDataProvider)
        let requestSignerV3 = JSONAPI.RequestSigner(keyDataProvider: keyDataProvider)
        
        let api = TokenDSDK.API(
            configuration: apiConfiguration,
            callbacks: apiCallbacks,
            network: network,
            requestSigner: requestSigner
        )
        
        let apiV3 = TokenDSDK.APIv3(
            configuration: apiConfiguration,
            callbacks: apiCallbacksV3,
            network: networkV3,
            requestSigner: requestSignerV3
        )
        
        let verifyApi = TokenDSDK.TFAVerifyApi(
            apiConfiguration: apiConfiguration,
            requestSigner: requestSigner,
            network: network
        )
        
        let keyServerApi = KeyServerApi(
            apiConfiguration: apiConfiguration,
            callbacks: apiCallbacks,
            verifyApi: verifyApi,
            requestSigner: requestSignerV3,
            network: network,
            networkV3: networkV3
        )
        
        let networkInfoRepo = NetworkInfoRepo(api: api.generalApi)
        
        self.api = api
        self.apiV3 = apiV3
        self.verifyApi = verifyApi
        self.keyServerApi = keyServerApi
        self.network = network
        self.apiConfigurationModel = apiConfigurationModel
        self.tfaDataProvider = tfaDataProvider
        self.networkInfoFetcher = networkInfoRepo
        self.settingsManager = settingsManager
    }
}

class BaseFlowController {
    
    var currentFlowController: FlowControllerProtocol?
    
    // MARK: - Public properties
    
    let appController: AppControllerProtocol
    let flowControllerStack: FlowControllerStack
    let rootNavigation: RootNavigationProtocol
    
    // MARK: - Private properties
    
    private var inputTFAText: String = ""
    
    private var contactPicker: CNContactPickerViewController?
    private var contactPickerHandler: ContactEmailPickerHandler?
    
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
    
    // MARK: - Public
    
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
    
    func showDialog(
        title: String?,
        message: String?,
        style: UIAlertController.Style,
        options: [String],
        onSelected: @escaping (_ selectedIndex: Int) -> Void,
        onCanceled: (() -> Void)?,
        presentViewController: PresentViewControllerClosure
        ) {
        
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: style
        )
        
        for (index, option) in options.enumerated() {
            alert.addAction(UIAlertAction(
                title: option,
                style: .default,
                handler: { _ in
                    onSelected(index)
            }))
        }
        
        alert.addAction(UIAlertAction(
            title: Localized(.cancel),
            style: .cancel,
            handler: { _ in
                onCanceled?()
        }))
        
        presentViewController(alert, true, nil)
    }
    
    func showSuccessMessage(
        title: String?,
        message: String?,
        completion: (() -> Void)?,
        presentViewController: PresentViewControllerClosure
        ) {
        
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: Localized(.ok),
            style: .default,
            handler: { _ in
                completion?()
        }))
        
        presentViewController(alert, true, nil)
    }
    
    // MARK: - Private
    
    private func onDefaultTFA(tfaInput: ApiCallbacks.TFAInput, cancel: @escaping () -> Void) {
        let alertTitle: String
        let alertMessage: String?
        switch tfaInput {
            
        case .password:
            alertTitle = Localized(.input_password)
            alertMessage = nil
            
        case .code(let type, _):
            switch type {
                
            case .email:
                alertTitle = Localized(.input_2fa_code)
                alertMessage = Localized(.input_code_sent_to_your_email)
                
            case .other(let source):
                alertTitle = Localized(.input_2fa_code)
                alertMessage = Localized(
                    .source,
                    replace: [
                        .source_replace_source: source
                    ]
                )
                
            case .totp:
                alertTitle = Localized(.input_2fa_code)
                alertMessage = Localized(.input_code_from_google_authenticator_or_similar_app)
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
                print(Localized(.unable_to_sign_tfa_asset_with_password))
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
                print(Localized(.unable_to_get_keychaindata_or_create_key_pair))
                return nil
        }
        
        guard let data = token.data(using: .utf8) else {
            print(Localized(.unable_to_encode_asset_to_data))
            return nil
        }
        
        guard let signedToken = try? ECDSA.signED25519(data: data, keyData: keyPair).base64EncodedString() else {
            print(Localized(.unable_to_sign_asset_data))
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
            title: Localized(.done),
            style: .default,
            handler: { _ in
                completion(self.inputTFAText)
        }))
        
        alert.addAction(UIAlertAction(
            title: Localized(.cancel_tfa),
            style: .cancel,
            handler: { _ in
                cancel()
        }))
        
        self.rootNavigation.presentAlert(alert, animated: true, completion: nil)
    }
    
    @objc private func tfaTextFieldEditingChanged(_ tf: UITextField) {
        self.inputTFAText = tf.text ?? ""
    }
    
    private func showEmailPickerForEmail(
        emails: [String],
        completion: @escaping (String) -> Void,
        onCanceled: (() -> Void)?,
        presentViewController: PresentViewControllerClosure
        ) {
        
        self.showDialog(
            title: Localized(.choose_email),
            message: nil,
            style: .actionSheet,
            options: emails,
            onSelected: { (index) in
                let email = emails[index]
                completion(email)
        },
            onCanceled: {
                onCanceled?()
        },
            presentViewController: presentViewController
        )
    }
}

extension BaseFlowController: FlowControllerProtocol {
    
    // MARK: - FlowControllerProtocol
    
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
    
    func presentContactEmailPicker(
        completion: @escaping (String) -> Void,
        presentViewController: @escaping PresentViewControllerClosure
        ) {
        
        let onPickerCompleted = { [weak self] in
            self?.contactPicker = nil
            self?.contactPickerHandler = nil
        }
        
        let delegate = ContactEmailPickerHandler(
            onCanceled: {
                onPickerCompleted()
        },
            onSelected: { [weak self] (emails) in
                onPickerCompleted()
                
                if emails.count == 1, let email = emails.first {
                    completion(email)
                    return
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: { [weak self] in
                    self?.showEmailPickerForEmail(
                        emails: emails,
                        completion: completion,
                        onCanceled: nil,
                        presentViewController: presentViewController
                    )
                })
        })
        
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = delegate
        
        contactPicker.predicateForEnablingContact = delegate.getPredicate()
        
        self.contactPicker = contactPicker
        self.contactPickerHandler = delegate
        
        presentViewController(contactPicker, true, nil)
    }
}
