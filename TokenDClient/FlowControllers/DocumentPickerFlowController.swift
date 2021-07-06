import UIKit
import MobileCoreServices

class DocumentPickerFlowController: BaseFlowController {
    
    typealias OnDidPickDocument = (Result<Document, Error>) -> Void
    typealias OnDidCancel = () -> Void
    
    struct Document {
        
        let name: String
        let data: Data
    }
    
    struct DocumentType: OptionSet {
        
        let rawValue: UInt8
        
        static let pdf: DocumentType = .init(rawValue: 1 << 0)
        static let jpeg: DocumentType = .init(rawValue: 1 << 1)
        static let gif: DocumentType = .init(rawValue: 1 << 2)
        static let tiff: DocumentType = .init(rawValue: 1 << 3)
        static let png: DocumentType = .init(rawValue: 1 << 4)
    }
    
    // MARK: Private properties
    
    private let delegate: DocumentPickerDelegate
    private let presentingViewController: UIViewController
    
    // MARK:
    
    init(
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        rootNavigation: RootNavigationProtocol,
        onDidPickDocument: @escaping OnDidPickDocument,
        onDidCancel: @escaping OnDidCancel,
        presentingViewController: UIViewController
    ) {
        
        delegate = .init(
            onDidPickDocument: onDidPickDocument,
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

extension DocumentPickerFlowController {
    
    func run(
        documentTypes: [DocumentType]
    ) {
        
        do {
            presentingViewController.present(
                try documentPickerController(
                    documentTypes: documentTypes
                ),
                animated: true,
                completion: nil
            )
        } catch {
            delegate.onDidPickDocument(.failure(error))
        }
    }
}

// MARK: Private methods

private extension DocumentPickerFlowController {
    
    func documentPickerController(
        documentTypes: [DocumentType]
    ) throws -> UIDocumentPickerViewController {
        
        let controller: UIDocumentPickerViewController = .init(
            documentTypes: try documentTypes.mapToUTIs(),
            in: .import
        )
        
        controller.delegate = delegate
        if #available(iOS 13.0, *) {
            controller.shouldShowFileExtensions = true
        }
        
        return controller
    }
}

// MARK: - DocumentPickerDelegate

private extension DocumentPickerFlowController {
    
    class DocumentPickerDelegate: NSObject {
        
        // MARK: Public properties
        
        fileprivate let onDidPickDocument: OnDidPickDocument
        fileprivate let onDidCancel: OnDidCancel
        
        // MARK:
        
        init(
            onDidPickDocument: @escaping OnDidPickDocument,
            onDidCancel: @escaping OnDidCancel
        ) {
            
            self.onDidPickDocument = onDidPickDocument
            self.onDidCancel = onDidCancel
            
            super.init()
        }
    }
}

extension DocumentPickerFlowController.DocumentPickerDelegate: UIDocumentPickerDelegate {
    
    enum PickerDidPickDocumentError: Swift.Error {
        
        case noUrl
    }
    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]
    ) {
        
        guard let url = urls.first
        else {
            onDidPickDocument(.failure(PickerDidPickDocumentError.noUrl))
            return
        }
        
        let data: Data
        do {
            data = try .init(contentsOf: url)
        } catch {
            onDidPickDocument(.failure(error))
            return
        }
        
        let name: String = url.lastPathComponent
        let document: DocumentPickerFlowController.Document = .init(
            name: name,
            data: data
        )
        onDidPickDocument(.success(document))
    }
    
    func documentPickerWasCancelled(
        _ controller: UIDocumentPickerViewController
    ) {
        
        onDidCancel()
    }
}

// MARK: -

private extension Array where Element == DocumentPickerFlowController.DocumentType {
    
    func mapToUTIs(
    ) throws -> [String] {
        
        try compactMap { try $0.mapToUTI() }
    }
}

private extension DocumentPickerFlowController.DocumentType {
    
    enum MapToUTIError: Swift.Error {
        case unknownUTI
    }
    func mapToUTI(
    ) throws -> String {
        
        switch self {
        
        case .gif: return String(kUTTypeGIF)
        case .jpeg: return String(kUTTypeJPEG)
        case .pdf: return String(kUTTypePDF)
        case .tiff: return String(kUTTypeTIFF)
        case .png: return String(kUTTypePNG)
        default: throw MapToUTIError.unknownUTI
        }
    }
}
