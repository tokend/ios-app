import UIKit

enum Assets: String {

    case none

    private var name: String {
        switch self {

        case .none: return "none"
        }
    }
}

extension Assets {
    
    public var image: UIImage {
        return UIImage(imageLiteralResourceName: self.name)
    }
}
