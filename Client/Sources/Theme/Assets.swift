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
    case touch_id_icon
    case face_id_icon
    case more_tab_icon
    case more_deposit_icon
    case more_explore_sales_icon
    case more_polls_icon
    case more_settings_icon
    case more_trade_icon
    case more_withdraw_icon
    case settings_language_icon
    case settings_account_id_icon
    case settings_verification_icon
    case settings_secret_seed_icon
    case settings_sign_out_icon
    case settings_lock_app_icon
    case settings_tfa_icon
    case settings_change_password_icon
    case buy_toolbar_icon
    case deposit_toolbar_icon
    case withdraw_toolbar_icon
    case receive_toolbar_icon
    case send_toolbar_icon

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
        case .touch_id_icon: return "touch_id_icon"
        case .face_id_icon: return "face_id_icon"
        case .more_tab_icon: return "more_tab_icon"
        case .more_deposit_icon: return "more_deposit_icon"
        case .more_explore_sales_icon: return "more_explore_sales_icon"
        case .more_polls_icon: return "more_polls_icon"
        case .more_settings_icon: return "more_settings_icon"
        case .more_trade_icon: return "more_trade_icon"
        case .more_withdraw_icon: return "more_withdraw_icon"
        case .settings_language_icon: return "settings_language_icon"
        case .settings_account_id_icon: return "settings_account_id_icon"
        case .settings_verification_icon: return "settings_verification_icon"
        case .settings_secret_seed_icon: return "settings_secret_seed_icon"
        case .settings_sign_out_icon: return "settings_sign_out_icon"
        case .settings_lock_app_icon: return "settings_lock_app_icon"
        case .settings_tfa_icon: return "settings_tfa_icon"
        case .settings_change_password_icon: return "settings_change_password_icon"
        case .buy_toolbar_icon: return "buy"
        case .deposit_toolbar_icon: return "deposit"
        case .withdraw_toolbar_icon: return "withdraw"
        case .receive_toolbar_icon: return "receive"
        case .send_toolbar_icon: return "send"
        }
    }
}

extension Assets {
    
    public var image: UIImage {
        return UIImage(imageLiteralResourceName: self.name)
    }
}
