import UIKit
import Nuke

enum TokenDUIImage {
    
    case url(URL)
    case uiImage(UIImage)
    
    init?(
        url: URL? = nil,
        uiImage: UIImage? = nil
    ) {
        
        if let url = url {
            self = .url(url)
        } else if let uiImage = uiImage {
            self = .uiImage(uiImage)
        } else {
            return nil
        }
    }
}

extension TokenDUIImage: Equatable {
    
    static func == (lhs: TokenDUIImage, rhs: TokenDUIImage) -> Bool {

        switch (lhs, rhs) {

        case (.url(let lhs), .url(let rhs)):
            return lhs == rhs

        case (.uiImage(let lhs), .uiImage(let rhs)):
            return lhs.pngData() == rhs.pngData()

        case (.url, .uiImage),
             (.uiImage, .url):
            return false
        }
    }
}

extension UIImageView {
    
    func setTokenDUIImage(_ tokenDImage: TokenDUIImage?) {
        switch tokenDImage {

        case .none:
            Nuke.cancelRequest(for: self)
            image = nil

        case .uiImage(let image):
            Nuke.cancelRequest(for: self)
            self.image = image

        case .url(let url):
            Nuke.loadImage(
                with: url,
                into: self
            )
        }
    }
}
