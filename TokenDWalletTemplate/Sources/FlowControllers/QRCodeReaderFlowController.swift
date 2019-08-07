import UIKit
import QRCodeReader

class QRCodeReaderFlowController: BaseFlowController {
    
    enum ReaderResult {
        case canceled
        case success(value: String, metadataType: String)
    }
    
    typealias QRCodeReaderCompletion = (_ result: ReaderResult) -> Void
    
    // MARK: - Public properties
    
    let presentingViewController: UIViewController
    let handler: QRCodeReaderCompletion
    
    // MARK: -
    
    init(
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        rootNavigation: RootNavigationProtocol,
        presentingViewController: UIViewController,
        handler: @escaping QRCodeReaderCompletion
        ) {
        
        self.presentingViewController = presentingViewController
        self.handler = handler
        
        super.init(
            appController: appController,
            flowControllerStack: flowControllerStack,
            rootNavigation: rootNavigation
        )
    }
    
    // MARK: - Public
    
    func run() {
        self.runPermissionRequestFlow()
    }
    
    // MARK: - Private
    
    private func runPermissionRequestFlow() {
        let flow = PermissionRequestFlowController(
            appController: self.appController,
            flowControllerStack: self.flowControllerStack,
            rootNavigation: self.rootNavigation,
            resource: .camera,
            onGranted: { [weak self] in
                self?.presentQRCodeReaderOnPermissionGranted()
            },
            onDenied: { [weak self] in
                self?.handler(.canceled)
        })
        self.currentFlowController = flow
        flow.run()
    }
    
    private func presentQRCodeReaderOnPermissionGranted() {
        let reader = QRCodeReaderViewController(builder: QRCodeReaderViewControllerBuilder {
            $0.readerView = QRCodeReaderContainer(displayable: QRCodeReaderView())
            $0.showOverlayView = true
            $0.showSwitchCameraButton = false
            $0.showTorchButton = true
            $0.handleOrientationChange = false
            $0.cancelButtonTitle = ""
            
        })
        reader.delegate = self
        self.presentingViewController.present(reader, animated: true, completion: nil)
    }
}

extension QRCodeReaderFlowController: QRCodeReaderViewControllerDelegate {
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.dismiss(animated: true) { [weak self] in
            self?.handler(.success(value: result.value, metadataType: result.metadataType))
        }
    }
    
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.dismiss(animated: true) { [weak self] in
            self?.handler(.canceled)
        }
    }
}
