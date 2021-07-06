import UIKit
import MobileCoreServices
import CoreFoundation

/// Can be used to pick image from camera or photos library. Use different `sourceType`.
/// `PHPickerFlowController` should be used instead for `iOS` verions newer than `14.0` to pick images from library.
/// Permission request is needed only for `.camera` `sourceType` after `iOS 11.0`.
///
/// Can pick **ONLY** one image at a time. To change this change `selectionLimit` and implement all dependent logic.
class UIImagePickerFlowController: BaseFlowController {
    
    typealias OnDidPickImage = (Result<UIImage, Error>) -> Void
    typealias OnDidCancel = () -> Void
    
    // MARK: Private properties
    
    private let selectionLimit: Int = 1
    private let delegate: ImagePickerDelegate
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
        
        self.delegate = .init(
            onDidPickImage: onDidPickImage,
            onDidCancel: onDidCancel
        )
        self.presentingViewController = presentingViewController
        
        super.init(
            appController: appController,
            flowControllerStack: flowControllerStack,
            rootNavigation: rootNavigation
        )
    }
}

// MARK: Public methods

extension UIImagePickerFlowController {
    
    func run(
        sourceType: UIImagePickerController.SourceType
    ) {
        
        presentingViewController.present(
            uiImagePickerController(sourceType: sourceType),
            animated: true,
            completion: nil
        )
    }
}

// MARK: Private methods

private extension UIImagePickerFlowController {
    
    func uiImagePickerController(
        sourceType: UIImagePickerController.SourceType
    ) -> UIImagePickerController {
        
        let controller: UIImagePickerController = .init()
        
        controller.allowsEditing = true
        controller.sourceType = sourceType
        if sourceType == .camera {
            controller.cameraCaptureMode = .photo
            controller.cameraFlashMode = .auto
            controller.showsCameraControls = true
            controller.cameraDevice = .rear
        }
        controller.delegate = delegate
        controller.mediaTypes = [String(kUTTypeImage)]
        
        return controller
    }
}

// MARK: - ImagePickerDelegate

private extension UIImagePickerFlowController {
    
    class ImagePickerDelegate: NSObject {
        
        // MARK: Public properties
        
        fileprivate let onDidPickImage: OnDidPickImage
        fileprivate let onDidCancel: OnDidCancel
        
        // MARK:
        
        init(
            onDidPickImage: @escaping OnDidPickImage,
            onDidCancel: @escaping OnDidCancel
        ) {
            
            self.onDidPickImage = onDidPickImage
            self.onDidCancel = onDidCancel
            
            super.init()
        }
    }
}

extension UIImagePickerFlowController.ImagePickerDelegate: UIImagePickerControllerDelegate {
    
    enum ImagePickerDidFinishPickingError: Swift.Error {
        
        case noImage
        case wrongMediaType
    }
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        
        guard let anyMediaType = info[.mediaType]
        else {
            return
        }
        
        picker.dismiss(
            animated: true,
            completion: nil
        )
        switch anyMediaType as! CFString {
        
        case kUTTypeImage:
            
            let image: UIImage?
            if picker.allowsEditing {
                image = info[.editedImage] as? UIImage
            } else {
                image = info[.originalImage] as? UIImage
            }
            
            if let image = image {
                onDidPickImage(.success(image))
            } else {
                onDidPickImage(.failure(ImagePickerDidFinishPickingError.noImage))
            }
            
        default:
            onDidPickImage(.failure(ImagePickerDidFinishPickingError.wrongMediaType))
        }
    }
    
    public func imagePickerControllerDidCancel(
        _ picker: UIImagePickerController
    ) {
        
        picker.dismiss(
            animated: true,
            completion: nil
        )
        onDidCancel()
    }
}

extension UIImagePickerFlowController.ImagePickerDelegate: UINavigationControllerDelegate { }
