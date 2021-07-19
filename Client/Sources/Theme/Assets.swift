import UIKit

enum Assets: String {

    case none
    case arrow_back_icon
    case arrow_up_icon
    case arrow_down_icon
    case arrow_right_icon
    case error_icon
    case password_is_hidden_icon
    case password_is_visible_icon
    case scan_qr_code_icon

    private var name: String {
        switch self {

        case .none: return "none"
        case .arrow_back_icon: return "arrow_back_icon"
        case .arrow_up_icon: return "arrow_up_icon"
        case .arrow_down_icon: return "arrow_down_icon"
        case .arrow_right_icon: return "arrow_right_icon"
        case .error_icon: return "error_icon"
        case .password_is_hidden_icon: return "password_is_hidden_icon"
        case .password_is_visible_icon: return "password_is_visible_icon"
        case .scan_qr_code_icon: return "scan_qr_code_icon"
        }
    }
}

extension Assets {
    
    public var image: UIImage {
        return UIImage(imageLiteralResourceName: self.name)
    }
}
