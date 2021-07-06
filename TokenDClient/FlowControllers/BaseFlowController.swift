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
    ) -> UIViewController! {

        return nil
    }
    
    /// - Parameters:
    ///   - onClosed: Called when screen is closed
    ///   - onCode: Called when TFA code is received
    func setupTFAPasswordScreen(
        onClosed: @escaping () -> Void,
        onCode: @escaping (String) -> Void
    ) -> UIAlertController! {
        
        return nil
    }
}

// MARK: - Private methods

private extension  BaseFlowController {
    
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
