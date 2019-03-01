import UIKit

enum AuthenticatorAuth {
    
    // MARK: - Typealiases
    
    typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    enum Model {}
    enum Event {}
}

// MARK: - Models

extension AuthenticatorAuth.Model {
    
    struct SceneModel {
        var publicKey: String?
        var qrSize: CGSize
    }
    
    enum AuthResultModel {
        case failure(String)
        case success(account: String)
    }
    
    enum AuthAppStateModel {
        case installed
        case notInstalled
        case cantInstall
    }
    
    enum AuthAppStateViewModel {
        case accessable(String)
        case inaccessable
    }
}

// MARK: - Events

extension AuthenticatorAuth.Event {
    typealias Model = AuthenticatorAuth.Model
    
    // MARK: -
    
    enum ViewDidLoad {
        struct Request {
            let qrSize: CGSize
        }
    }
    
    enum ActionButtonClicked {
        struct Request { }
        
        struct Response {
            let url: URL?
        }
        typealias ViewModel = Response
    }
    
    enum SetupActionButton {
        
        struct Resposne {
            let state: Model.AuthAppStateModel
        }
        
        struct ViewModel {
            let state: Model.AuthAppStateViewModel
        }
    }
    
    enum UpdateQRContent {
        
        struct Response {
            let url: URL?
            let qrSize: CGSize
        }
        
        struct ViewModel {
            let qrImage: UIImage
        }
    }
    
    enum FetchedAuthResult {
        struct Response {
            let result: Model.AuthResultModel
        }
        
        typealias ViewModel = Response
    }
}
