import Foundation

enum RecoverySeed {
    
    // MARK: - Typealiases
    
    // MARK: -
    
    enum Model {}
    enum Event {}
}

// MARK: - Models

extension RecoverySeed.Model {
    typealias WalletData = RegisterScene.Model.WalletData
    
    struct SceneModel {
        let seed: String
        var userInputSeed: String?
    }
    
    enum InputSeedValidation {
        case empty
        case valid
        case invalid
    }
}

// MARK: - Events

extension RecoverySeed.Event {
    typealias Model = RecoverySeed.Model
    
    enum ViewDidLoad {
        struct Request {}
        
        struct Response {
            let seed: String
            let inputSeedValid: RecoverySeed.Model.InputSeedValidation
        }
        
        struct ViewModel {
            let text: NSAttributedString
            let inputSeedValid: RecoverySeed.Model.InputSeedValidation
        }
    }
    
    enum ValidationSeedEditing {
        struct Request {
            let value: String?
        }
        
        struct Response {
            let inputSeedValid: RecoverySeed.Model.InputSeedValidation
        }
        
        struct ViewModel {
            let inputSeedValid: RecoverySeed.Model.InputSeedValidation
        }
    }
    
    enum CopyAction {
        struct Request {}
        
        struct Response {
            let message: String
        }
        
        struct ViewModel {
            let message: String
        }
    }
    
    enum ProceedAction {
        struct Request {}
    }
    
    enum ShowWarning {
        struct Response {}
        typealias ViewModel = Response
    }
    
    enum SignUpAction {
        struct Request {}
        enum Response {
            case loading
            case loaded
            case success(account: String, walletData: Model.WalletData)
            case error(RecoverySeedSignUpWorkerResult.SignUpError)
        }
        
        enum ViewModel {
            case loading
            case loaded
            case success(account: String, walletData: Model.WalletData)
            case error(String)
        }
    }
}
