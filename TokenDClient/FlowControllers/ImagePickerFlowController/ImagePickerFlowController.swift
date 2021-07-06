import UIKit

/// Used to pick images from library.
/// Permission request is not needed. To pick image from camera use `UIImagePickerFlowController` with `.camera` `sourceType`.
///
/// Can pick **ONLY** one image at a time. See `UIImagePickerFlowController` and `PHPickerFlowController` for details.
class ImagePickerFlowController: BaseFlowController {
    
    typealias OnDidPickImage = (Result<UIImage, Error>) -> Void
    typealias OnDidCancel = () -> Void
    
    // MARK: Private properties
    
    private let onDidPickImage: OnDidPickImage
    private let onDidCancel: OnDidCancel
    private let presentingViewController: UIViewController
    
    // MARK:
    
    init(
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        rootNavigation: RootNavigationProtocol,
        onDidPickImage: @escaping OnDidPickImage,
        onDidCancel: @escaping OnDidCancel,
        presentingViewController: UIViewController
    ) {
        
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

extension ImagePickerFlowController {
    
    func run(
    ) {
        
        if #available(iOS 14.0, *) {
            let flow: PHPickerFlowController = .init(
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
        } else {
            let flow: UIImagePickerFlowController = .init(
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
            
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                flow.run(sourceType: .photoLibrary)
            } else if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
                flow.run(sourceType: .savedPhotosAlbum)
            }
        }
    }
}
