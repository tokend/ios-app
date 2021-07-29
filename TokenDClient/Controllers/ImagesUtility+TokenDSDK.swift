import Foundation
import TokenDSDK

extension ImagesUtility {
    
    public func getImageURL(
        _ attachment: BlobResponse.Attachment?
    ) -> URL? {
        
        guard let attachment = attachment
        else {
            return nil
        }
        
        return getImageURL(.key(attachment.key))
    }
}
