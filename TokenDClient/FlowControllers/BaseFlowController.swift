import UIKit
import TokenDSDK
import DLCryptoKit

class BaseFlowController: FlowControllerProtocol {
    
    var currentFlowController: FlowControllerProtocol?
    
    // MARK: - Public properties
    
    let appController: AppControllerProtocol
    let flowControllerStack: FlowControllerStack
    let rootNavigation: RootNavigationProtocol
    
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

    deinit {
        print(.deinit(object: self))
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
    
    func showBlockingProgress() { }
    
    func hideBlockingProgress() { }
    
    // MARK: - QRCodeReader
    
    func runQRCodeReaderFlow(
        presentingViewController: UIViewController,
        handler: @escaping QRCodeReaderFlowController.QRCodeReaderCompletion
    ) {
        let flow = QRCodeReaderFlowController(
            appController: self.appController,
            flowControllerStack: self.flowControllerStack,
            rootNavigation: self.rootNavigation,
            presentingViewController: presentingViewController,
            handler: { [weak self] (result) in
                self?.currentFlowController = nil
                handler(result)
        })
        self.currentFlowController = flow
        flow.run()
    }
    
    // MARK: - TFA
    
    func performTFA(tfaInput: ApiCallbacks.TFAInput, cancel: @escaping () -> Void) { }
    
    func handleTFASecret(_ secret: String, seed: String, completion: @escaping (_ shouldContinue: Bool) -> Void) { }
    
    /// Sets up TFA handling flow
    /// - Parameters:
    ///   - tfaInput: Requested TFA type and input data
    ///   - onDone: Called when user have entered TFA code
    ///   - onClose: Called when TFA code was sent
    ///   - cancel: Called when user cancelled TFA codee
    /// - Returns: First view controller in TFA handling flow
    func setupTFA(
        tfaInput: ApiCallbacks.TFAInput,
        onDone: @escaping () -> Void,
        onClose: @escaping () -> Void,
        cancel: @escaping () -> Void
    ) -> UIViewController {
        
        let onCode: (String, (_ code: String, _ completion: @escaping () -> Void) -> Void) -> Void = { [weak self] (code, inputCallback) in
            
            self?.processTFACode(
                code,
                for: tfaInput,
                onCode: { (signedToken) in
                    onDone()
                    inputCallback(
                        signedToken,
                        {
                            onClose()
                        }
                    )
                },
                onError: { (_) in
                    cancel()
                }
            )
        }
        
        switch tfaInput {
        
        case .password(_, let inputCallback):
            
            return setupTFAPasswordScreen(
                onClosed: cancel,
                onCode: { (code) in
                    onCode(code, { (code, completion) in
                        inputCallback(code, completion)
                    })
                }
            )
            
        case .code(_, let inputCallback):
            
            return setupTFACodeScreen(
                onClosed: cancel,
                onCode: { (code) in
                    onCode(code, { (code, completion) in
                        inputCallback(code, completion)
                    })
                }
            )
        }
    }
    
    /// - Parameters:
    ///   - onClosed: Called when screen is closed
    ///   - onCode: Called when TFA code is received
    func setupTFACodeScreen(
        onClosed: @escaping () -> Void,
        onCode: @escaping (String) -> Void
    ) -> UIViewController {

        let alert = UIAlertController(
            title: Localized(.tfa_code_title),
            message: nil,
            preferredStyle: .alert
        )
        
        alert.addTextField(
            configurationHandler: { (textField) in
                textField.placeholder = Localized(.tfa_code_placeholder)
                textField.isSecureTextEntry = true
            }
        )
        
        alert.addAction(
            UIAlertAction(
                title: Localized(.done),
                style: .default,
                handler: { (_) in
                    guard let textField = alert.textFields?.first,
                          let code = textField.text
                    else {
                        onClosed()
                        return
                    }

                    onCode(code)
                }
            )
        )
        
        alert.addAction(
            UIAlertAction(
                title: Localized(.cancel),
                style: .cancel,
                handler: { (_) in
                    onClosed()
                }
            )
        )
        
        return alert
    }
    
    /// - Parameters:
    ///   - onClosed: Called when screen is closed
    ///   - onCode: Called when TFA code is received
    func setupTFAPasswordScreen(
        onClosed: @escaping () -> Void,
        onCode: @escaping (String) -> Void
    ) -> UIViewController {
        
        let alert = UIAlertController(
            title: Localized(.tfa_password_title),
            message: nil,
            preferredStyle: .alert
        )
        
        alert.addTextField(
            configurationHandler: { (textField) in
                textField.placeholder = Localized(.tfa_password_placeholder)
                textField.isSecureTextEntry = true
            }
        )
        
        alert.addAction(
            UIAlertAction(
                title: Localized(.done),
                style: .default,
                handler: { (_) in
                    guard let textField = alert.textFields?.first,
                          let password = textField.text
                    else {
                        onClosed()
                        return
                    }

                    onCode(password)
                }
            )
        )
        
        alert.addAction(
            UIAlertAction(
                title: Localized(.cancel),
                style: .cancel,
                handler: { (_) in
                    onClosed()
                }
            )
        )
        
        return alert
    }
    
    func setupTFASecretAlert(
        _ secret: String,
        seed: String,
        completion: @escaping (Bool) -> Void
    ) -> UIAlertController {
        
        let alert = UIAlertController(
            title: Localized(.tfa_setup_tfa),
            message: Localized(
                .to_enable_two_factor_authentication,
                replace: [
                    .to_enable_two_factor_authentication_replace_secret: secret
                ]
            ),
            preferredStyle: .alert
        )
        
        alert.addAction(
            UIAlertAction(
                title: Localized(.copy),
                style: .default,
                handler: { _ in
                    UIPasteboard.general.string = secret
                    
                    completion(true)
                }
            )
        )
        
        if let url = URL(string: seed),
           UIApplication.shared.canOpenURL(url) {
            alert.addAction(
                UIAlertAction(
                    title: Localized(.open_app),
                    style: .default,
                    handler: { _ in
                        UIPasteboard.general.string = secret
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        
                        completion(true)
                    }
                )
            )
        }
        
        alert.addAction(
            UIAlertAction(
                title: Localized(.cancel),
                style: .cancel,
                handler: { _ in
                    completion(false)
                }
            )
        )
        
        return alert
    }
}

// MARK: - Private methods

private extension BaseFlowController {
    
    func processTFACode(
        _ code: String,
        for input: ApiCallbacks.TFAInput,
        onCode: (String) -> Void,
        onError: (Swift.Error) -> Void
    ) {
        
        let tfaCodeProcessor: TFACodeProcessorProtocol
        
        switch input {
        
        case .password(let tokenSignData, _):
            tfaCodeProcessor = PasswordTFAProcessor(
                tokenSignData: tokenSignData,
                tfaDataProvider: flowControllerStack.tfaDataProvider
            )
            
        case .code:
            tfaCodeProcessor = DefaultTFACodeProcessor()
        }
        
        do {
            let code = try tfaCodeProcessor.process(
                tfaCode: code
            )
            onCode(code)
        } catch {
            onError(error)
        }
    }
}
