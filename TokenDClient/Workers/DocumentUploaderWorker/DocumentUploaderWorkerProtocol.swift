import UIKit
import TokenDSDK

public protocol DocumentUploaderWorkerProtocol {
    
    /// Uploads any supported iimage.
    ///
    /// Supported image types:
    ///  - image/jpeg
    /// - Parameters:
    ///   - image: image of supported type.
    ///   - name: image name, if `nil` uses current date as name
    ///   - contentType: image content type, if `nil` derives content type from data.
    ///   - uploadPolicy: `UploadPolicy.PolicyType`.
    ///   - completion: called on upload finished or error.
    ///     - `BlobResponse.BlobContent.Attachment` if success and `Swift.Error` if failure.
    func upload(
        image: UIImage,
        name: String?,
        contentType: String?,
        uploadPolicy: String,
        completion: @escaping (Swift.Result<UploadedAttachment, Swift.Error>) -> Void
    )
    
    /// Uploads any supported document.
    ///
    /// Supported document types:
    ///  - image/jpeg
    ///  - application/pdf
    /// - Parameters:
    ///   - document: document data. Can be any document of supported type.
    ///   - name: document name, if `nil` uses current date as name
    ///   - contentType: document content type, if `nil` derives content type from data.
    ///   - uploadPolicy: `UploadPolicy.PolicyType`.
    ///   - completion: called on upload finished or error.
    ///     - `BlobResponse.BlobContent.Attachment` if success and `Swift.Error` if failure.
    func upload(
        document: Data,
        name: String?,
        contentType: String?,
        uploadPolicy: String,
        completion: @escaping (Swift.Result<UploadedAttachment, Swift.Error>) -> Void
    )
}

public typealias UploadedAttachment = BlobResponse.Attachment
