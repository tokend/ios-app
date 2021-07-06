import Foundation
import TokenDSDK

enum AccountKYCFormSenderResult {

    case success
    case failure(Swift.Error)
}

protocol AccountKYCForm: Encodable {
    
    var documents: [String: KYCDocument] { get }
    
    func update(
        with documents: [String: KYCDocument]
    ) -> Self
}

protocol AccountKYCFormSenderProtocol {

    func sendKYCForm(
        _ form: AccountKYCForm,
        roleId: UInt64,
        completion: @escaping (AccountKYCFormSenderResult) -> Void
    )
}

enum Document<Data: Equatable>: Codable, Equatable {
    case uploaded(BlobResponse.BlobContent.Attachment)
    case new(Data, uploadPolicy: String)
    
    init(from decoder: Decoder) throws {
        
        let attachment: BlobResponse.BlobContent.Attachment = try .init(from: decoder)
        self = .uploaded(attachment)
    }
    
    enum EncodingError: Swift.Error {
        case cannotEncodeData(Data)
    }
    func encode(to encoder: Encoder) throws {
        
        switch self {
        
        case .new(let data, _):
            throw EncodingError.cannotEncodeData(data)
            
        case .uploaded(let attachment):
            var container = encoder.singleValueContainer()
            try container.encode(attachment)
        }
    }
}

extension BlobResponse.BlobContent.Attachment: Equatable {

    public typealias SelfType = BlobResponse.BlobContent.Attachment

    public static func ==(left: SelfType, right: SelfType) -> Bool {

        return left.key == right.key
            && left.mimeType == right.mimeType
            && left.name == right.name
    }
}

extension AccountKYCForm {
    
    typealias KYCDocument = Document<UIImage>
}
