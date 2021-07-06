import UIKit

class MediaPickerFlowController: BaseFlowController {
    
    typealias OnDidPickDocument = (Result<DocumentPickerFlowController.Document, Error>) -> Void
    typealias OnDidPickImage = (Result<UIImage, Error>) -> Void
    typealias OnDidCancel = () -> Void
    
    // MARK: Private properties
    
    private let onDidPickDocument: OnDidPickDocument
    private let onDidPickImage: OnDidPickImage
    private let onDidCancel: OnDidCancel
    private let presentingViewController: UIViewController
    
    // MARK:
    
    init(
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        rootNavigation: RootNavigationProtocol,
        onDidPickDocument: @escaping OnDidPickDocument,
        onDidPickImage: @escaping OnDidPickImage,
        onDidCancel: @escaping OnDidCancel,
        presentingViewController: UIViewController
    ) {
        
        self.onDidPickDocument = onDidPickDocument
        self.onDidPickImage = onDidPickImage
        self.onDidCancel = onDidCancel
        self.presentingViewController = presentingViewController
        
        super.init(
            appController: appController,
            flowControllerStack: flowControllerStack,
            rootNavigation: rootNavigation
        )
    }
}

// MARK: Public methods

extension MediaPickerFlowController {
    
    func run(
    ) {
        
        presentingViewController.present(
            sourceTypePicker(),
            animated: true,
            completion: nil
        )
    }
}

// MARK: Private methods

private extension MediaPickerFlowController {
    
    func sourceTypePicker(
    ) -> UIAlertController {
        
        let controller: UIAlertController = .init()
        
        // Define CAMERA in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use contacts
        #if CAMERA
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let action: UIAlertAction = .init(
                title: Localized(.mediapicker_sourcetype_camera_title),
                style: .default,
                handler: { [weak self] (_) in
                    self?.showCamera()
                }
            )
            controller.addAction(action)
        }
        #endif
        
        let documentAction: UIAlertAction = .init(
            title: Localized(.mediapicker_sourcetype_documents_title),
            style: .default,
            handler: { [weak self] (_) in
                self?.showDocumentsPicker()
            }
        )
        controller.addAction(documentAction)
        
        let libraryAction: UIAlertAction = .init(
            title: Localized(.mediapicker_sourcetype_photolibrary_title),
            style: .default,
            handler: { [weak self] (_) in
                self?.showImagePicker()
            }
        )
        controller.addAction(libraryAction)
        
        if controller.actions.count > 0 {
            controller.addAction(
                .init(
                    title: Localized(.cancel),
                    style: .cancel,
                    handler: { [weak self] (_) in
                        self?.onDidCancel()
                    }
                )
            )
        }
        
        return controller
    }
    
    // Define CAMERA in Build Settings in Swift Compiler - Custom Flags in Active Compilation Conditions to use contacts
    #if CAMERA
    func showCamera(
    ) {
        
        let flow: PermissionRequestFlowController = .init(
            appController: appController,
            flowControllerStack: flowControllerStack,
            rootNavigation: rootNavigation,
            resource: .camera,
            onGranted: { [weak self] in
                
                guard let self = self else { return }
                let flow: UIImagePickerFlowController = .init(
                    appController: self.appController,
                    flowControllerStack: self.flowControllerStack,
                    rootNavigation: self.rootNavigation,
                    onDidPickImage: { [weak self] (result) in
                        self?.onDidPickImage(result)
                    },
                    onDidCancel: { [weak self] in
                        self?.currentFlowController = nil
                        self?.onDidCancel()
                    },
                    presentingViewController: self.presentingViewController
                )
                self.currentFlowController = flow
                flow.run(sourceType: .camera)
            },
            onDenied: { [weak self] in
                self?.currentFlowController = nil
                self?.onDidCancel()
            }
        )
        
        currentFlowController = flow
        flow.run()
    }
    #endif
    
    func showDocumentsPicker(
    ) {
        
        let flow: DocumentPickerFlowController = .init(
            appController: appController,
            flowControllerStack: flowControllerStack,
            rootNavigation: rootNavigation,
            onDidPickDocument: { [weak self] (result) in
                self?.onDidPickDocument(result)
            },
            onDidCancel: { [weak self] in
                self?.currentFlowController = nil
                self?.onDidCancel()
            },
            presentingViewController: presentingViewController
        )
        
        currentFlowController = flow
        flow.run(
            documentTypes: [.gif, .jpeg, .pdf, .png, .tiff]
        )
    }
    
    func showImagePicker(
    ) {
        
        let flow: ImagePickerFlowController = .init(
            appController: appController,
            flowControllerStack: flowControllerStack,
            rootNavigation: rootNavigation,
            onDidPickImage: { [weak self] (result) in
                self?.onDidPickImage(result)
            },
            onDidCancel: { [weak self] in
                self?.currentFlowController = nil
                self?.onDidCancel()
            },
            presentingViewController: presentingViewController
        )
        
        currentFlowController = flow
        flow.run()
    }
}
