import Foundation

enum UpdatePassword {
    
    // MARK: - Typealiases
    
    // MARK: -
    
    enum Model {}
    enum Event {}
}

// MARK: - Models

extension UpdatePassword.Model {
    class SceneModel {
        var fields: [Field]
        
        init(fields: [Field]) {
            self.fields = fields
        }
    }
    
    class Field {
        let type: FieldType
        var value: String?
        
        init(type: FieldType, value: String?) {
            self.type = type
            self.value = value
        }
    }
    
    enum FieldType {
        case email
        case seed
        case oldPassword
        case newPassword
        case confirmPassword
    }
}

// MARK: - Events

extension UpdatePassword.Event {
    enum ViewDidLoadSync {
        struct Request {}
        
        struct Response {
            let fields: [UpdatePassword.Model.Field]
        }
        
        struct ViewModel {
            let fields: [UpdatePassword.View.Field]
        }
    }
    
    enum FieldEditing {
        struct Request {
            let fieldType: UpdatePassword.Model.FieldType
            let text: String?
        }
    }
    
    enum SubmitAction {
        struct Request { }
        
        enum Response {
            case loaded
            case loading
            case succeeded
            case failed(ErrorModel)
        }
        
        enum ViewModel {
            case loaded
            case loading
            case succeeded
            case failed(ErrorViewModel)
        }
    }
}

extension UpdatePassword.Event.SubmitAction.Response {
    enum ErrorModel {
        case emptyField(UpdatePassword.Model.FieldType)
        case incorrectSeed
        case passwordInvalid(String)
        case passwordsDontMatch
        case submitError(UpdatePassword.SubmitPasswordHandler.Result.SubmitError)
        case networkInfoFetchFailed(Error)
    }
}
extension UpdatePassword.Event.SubmitAction.ViewModel {
    struct ErrorViewModel {
        let message: String
        let error: UpdatePassword.Event.SubmitAction.Response.ErrorModel
    }
}
