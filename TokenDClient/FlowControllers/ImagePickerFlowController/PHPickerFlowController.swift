import UIKit
import PhotosUI

/// Should be used instead of `UIImagePickerFlowController` for `iOS` verions newer than `14.0` to pick images from library.
/// Permission request is not needed. To pick image from camera use `UIImagePickerFlowController` with `.camera` `sourceType`.
///
/// Can pick **ONLY** one image at a time. To change this change `selectionLimit` and implement all dependent logic.
@available(iOS 14.0, *)
class PHPickerFlowController: BaseFlowController {
    
    typealias OnDidPickImage = (Result<UIImage, Error>) -> Void
    typealias OnDidCancel = () -> Void
    
    // MARK: Private properties
    
    private let selectionLimit: Int = 1
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

@available(iOS 14.0, *)
extension PHPickerFlowController {
    
    func run() {
        
        presentingViewController.present(
            phPickerViewController(),
            animated: true,
            completion: nil
        )
    }
}

// MARK: Private methods

@available(iOS 14.0, *)
private extension PHPickerFlowController {
    
    func phPickerViewController(
    ) -> PHPickerViewController {
        
        var configuration: PHPickerConfiguration = .init()
        configuration.selectionLimit = selectionLimit
        configuration.filter = .images
        
        let controller: PHPickerViewController = .init(
            configuration: configuration
        )
        
        controller.delegate = self
        
        return controller
    }
}

// MARK: PHPickerViewControllerDelegate

@available(iOS 14.0, *)
extension PHPickerFlowController: PHPickerViewControllerDelegate {
    
    enum PickerDidFinishPickingError: Swift.Error {
        
        case unhandledState
    }
    func picker(
        _ picker: PHPickerViewController,
        didFinishPicking results: [PHPickerResult]
    ) {
        
        if selectionLimit == 1,
           results.count == selectionLimit,
           let result = results.first {
            
            result.itemProvider.loadImage(
                completion: { [weak self] (result) in
                    
                    DispatchQueue.main.async { [weak self] in
                        picker.dismiss(
                            animated: true,
                            completion: nil
                        )
                        switch result {
                        
                        case .failure(let error):
                            self?.onDidPickImage(.failure(error))
                            
                        case .success(let image):
                            self?.onDidPickImage(.success(image))
                        }
                    }
                }
            )
        } else if results.isEmpty {
            picker.dismiss(
                animated: true,
                completion: nil
            )
            onDidCancel()
        } else {
            print(.fatalError(error: "Add handling of selection count more than one"))
            picker.dismiss(
                animated: true,
                completion: nil
            )
            self.onDidPickImage(.failure(PickerDidFinishPickingError.unhandledState))
        }
    }
}

extension NSItemProvider {
    
    enum LoadImageError: Swift.Error {
        case cannotLoad
        case unknown
    }
    func loadImage(
        completion: @escaping (Swift.Result<UIImage, Swift.Error>) -> Void
    ) {
        
        if canLoadObject(ofClass: UIImage.self) {
            loadObject(
                ofClass: UIImage.self,
                completionHandler: { (image, error) in
                    if let image = image as? UIImage {
                        completion(.success(image))
                        return
                    }
                    
                    guard let error = error
                    else {
                        completion(.failure(LoadImageError.unknown))
                        return
                    }
                    completion(.failure(error))
                })
        } else {
            completion(.failure(LoadImageError.cannotLoad))
        }
    }
}
