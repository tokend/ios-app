import UIKit
import TokenDSDK

final class DocumentUploaderWorker {
    
    // MARK: - Private properties

    private let documentsApi: DocumentsApi
    private let originalAccountId: String
    private let supportedContentTypes: [ImageFormat] = [.jpeg]
    
    // MARK: -

    init(
        documentsApi: DocumentsApi,
        originalAccountId: String
    ) {

        self.documentsApi = documentsApi
        self.originalAccountId = originalAccountId
    }
}

private extension DocumentUploaderWorker {
    
    func convertImage(
        _ image: UIImage,
        name: String?,
        contentType: String? = nil,
        uploadPolicy: String,
        completion: @escaping (Swift.Result<UploadedAttachment, Swift.Error>) -> Void
    ) {
        
        guard let data = image.jpegData(compressionQuality: 1.0)
            else {
                completion(.failure(RequestUploadPolicyError.cannotGetJPEDData))
                return
        }

        guard supportedContentTypes.contains(data.imageFormat)
            else {
                completion(.failure(RequestUploadPolicyError.unsupportedImageMimeType))
                return
        }
        
        requestUploadPolicy(
            data,
            name: name,
            contentType: contentType,
            uploadPolicy: uploadPolicy,
            completion: completion
        )
    }
    
    enum RequestUploadPolicyError: Swift.Error {
        case cannotGetJPEDData
        case unsupportedImageMimeType
    }
    func requestUploadPolicy(
        _ document: Data,
        name: String?,
        contentType: String? = nil,
        uploadPolicy: String,
        completion: @escaping (Swift.Result<UploadedAttachment, Swift.Error>) -> Void
    ) {
        
        let type: String
        
        if let contentType = contentType {
            type = contentType
        } else {
            
            do {
                type = try document.contentType()
            } catch {
                completion(.failure(error))
                return
            }
        }
        
        documentsApi.getUploadPolicy(
            type: uploadPolicy,
            contentType: type,
            ownerAccountId: originalAccountId,
            completion: { [weak self] (result) in
                
                switch result {
                
                case .failure(let error):
                    completion(.failure(error))
                    
                case .success(let response):
                    self?.uploadDocument(
                        policy: response,
                        documentData: document,
                        fileName: name ?? "\(Date())",
                        mimeType: type,
                        completion: completion
                    )
                }
            })
    }
    
    func uploadDocument(
        policy: GetUploadPolicyResponse,
        documentData: Data,
        fileName: String,
        mimeType: String,
        completion: @escaping (Swift.Result<UploadedAttachment, Swift.Error>) -> Void
    ) {

        _ = documentsApi.uploadDocument(
            uploadPolicy: policy,
            uploadOption: .data(
                data: documentData,
                meta: .init(
                    fileName: fileName,
                    mimeType: mimeType
                )
            ),
            completion: { (result) in

                switch result {

                case .failure(let error):
                    completion(.failure(error))
                    
                case .success:
                    completion(.success(
                        .init(
                            mimeType: mimeType,
                            name: fileName,
                            key: policy.attributes.key
                        )
                    ))
                }
        })
    }
}

extension DocumentUploaderWorker: DocumentUploaderWorkerProtocol {
    
    func upload(
        document: Data,
        name: String? = nil,
        contentType: String? = nil,
        uploadPolicy: String,
        completion: @escaping (Result<UploadedAttachment, Error>) -> Void
    ) {
        
        requestUploadPolicy(
            document,
            name: name,
            uploadPolicy: uploadPolicy,
            completion: completion
        )
    }
    
    func upload(
        image: UIImage,
        name: String? = nil,
        contentType: String? = nil,
        uploadPolicy: String,
        completion: @escaping (Result<UploadedAttachment, Error>) -> Void
    ) {
        
        convertImage(
            image,
            name: name,
            uploadPolicy: uploadPolicy,
            completion: completion
        )
    }
}

public enum ImageFormat {
    case png
    case jpeg
    case gif
    case tiff
    case unknown

    init(
        buffer: [UInt8]
    ) {

        if buffer == ImageHeaderData.PNG
        {
            self = .png
        } else if buffer == ImageHeaderData.JPEG
        {
            self = .jpeg
        } else if buffer == ImageHeaderData.GIF
        {
            self = .gif
        } else if buffer == ImageHeaderData.TIFF_01 || buffer == ImageHeaderData.TIFF_02{
            self = .tiff
        } else{
            self = .unknown
        }
    }

    enum ContentTypeError: Swift.Error {
        case unknownContentType
    }
    func contentType() throws -> String {
        switch self {

        case .jpeg:
            return UploadPolicy.ContentType.imageJpeg
        case .gif:
            return UploadPolicy.ContentType.imageGif
        case .tiff:
            return UploadPolicy.ContentType.imageTiff
        case .png:
            return UploadPolicy.ContentType.imagePng
        case .unknown:
            throw ContentTypeError.unknownContentType
        }
    }
}

private struct ImageHeaderData {
    static var PNG: [UInt8] = [0x89]
    static var JPEG: [UInt8] = [0xFF]
    static var GIF: [UInt8] = [0x47]
    static var TIFF_01: [UInt8] = [0x49]
    static var TIFF_02: [UInt8] = [0x4D]
}

private extension Data{
    var imageFormat: ImageFormat {
        var buffer = [UInt8](repeating: 0, count: 1)
        self.copyBytes(to: &buffer, count: 1)
        return ImageFormat(buffer: buffer)
    }
    
    enum ContentTypeError: Swift.Error {
        
        case unsupportedContentType
    }
    func contentType() throws -> String {
        var b: UInt8 = 0
        copyBytes(to: &b, count: 1)
        
        switch b {
        case 0xFF:
            return "image/jpeg"
        case 0x89:
            return "image/png"
        case 0x47:
            return "image/gif"
        case 0x4D, 0x49:
            return "image/tiff"
        case 0x25:
            return "application/pdf"
        default:
            throw ContentTypeError.unsupportedContentType
        }
    }
}
