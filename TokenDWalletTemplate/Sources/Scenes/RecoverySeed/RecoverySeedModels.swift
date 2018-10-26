import Foundation

enum RecoverySeed {
    
    // MARK: - Typealiases
    
    // MARK: -
    
    enum Model {}
    enum Event {}
}

// MARK: - Models

extension RecoverySeed.Model {
    
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
    enum ViewDidLoad {
        struct Request {}
        
        struct Response {
            let seed: String
            let inputSeedValid: RecoverySeed.Model.InputSeedValidation
        }
        
        struct ViewModel {
            let seed: String
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
        
        enum Response {
            case showMessage
            case proceed
        }
        
        enum ViewModel {
            case showMessage
            case proceed
        }
    }
}
