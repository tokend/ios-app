import UIKit
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
    
    func handleTFASecret(_ secret: String, seed: String, completion: @escaping (_ shouldContinue: Bool) -> Void)
}
