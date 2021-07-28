import Foundation

public extension Document {

    func imageUrl(
        imagesUtility: ImagesUtility
    ) -> URL? {

        switch self {

        case .new:
            return nil

        case .uploaded(let attachment):
            return imagesUtility.getImageURL(attachment)
        }
    }
}

