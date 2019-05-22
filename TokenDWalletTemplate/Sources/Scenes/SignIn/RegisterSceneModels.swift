import Foundation

enum RegisterScene {
    
    // MARK: - Typealiases
    
    typealias QRCodeReaderCompletion = (_ result: Model.QRCodeReaderResult) -> Void
    
    // MARK: -
    
    enum Model {}
    enum Event {}
}

// MARK: - Models

extension RegisterScene.Model {
    class Field {
        
        let type: FieldType
        var text: String?
        let editable: Bool
        let actionType: ActionType
        
        init(
            type: FieldType,
            text: String?,
            editable: Bool = true,
            actionType: ActionType = .none
            ) {
            
            self.type = type
            self.text = text
            self.editable = editable
            self.actionType = actionType
        }
    }
    
    enum SubAction {
        case signUp
        case signIn
        case authenticator
        case recovery
        case signOut
        case agreeOnTerms(checked: Bool, link: URL)
    }
    
    class SceneModel {
        
        let state: State
        var fields: [Field]
        var subActions: [SubAction]
        let termsUrl: URL?
        
        static func empty(termsUrl: URL?) -> SceneModel {
            let model = SceneModel(
                state: .signIn,
                fields: [],
                subActions: [],
                termsUrl: termsUrl
            )
            return model
        }
        
        static func signInWithEmail(
            _ email: String?,
            state: State = .signIn,
            termsUrl: URL? = nil
            ) -> SceneModel {
            
            let model = SceneModel(
                state: state,
                fields: [
                    Field(
                        type: .text(purpose: .email),
                        text: email,
                        editable: state != .localAuth
                    )
                ],
                subActions: [],
                termsUrl: termsUrl
            )
            return model
        }
        
        init(
            state: State,
            fields: [Field],
            subActions: [SubAction],
            termsUrl: URL?
            ) {
            
            self.state = state
            self.fields = fields
            self.subActions = subActions
            self.termsUrl = termsUrl
        }
    }
    
    enum SubActionViewModel {
        case text(NSAttributedString)
        case agreeOnTerms(checked: Bool)
    }
    
    struct SceneViewModel {
        
        let title: String
        let fields: [RegisterScene.View.Field]
        let actionTitle: String
        let subActions: [SubActionViewModel]
    }
    
    typealias WalletData = WalletDataSerializable
    
    enum QRCodeReaderResult {
        case canceled
        case success(value: String, metadataType: String)
    }
    
    struct ServerInfoParsed: Decodable {
        let api: String
        let storage: String
        let kyc: String
        let terms: String?
        let web: String?
        let download: String?
    }
}

extension RegisterScene.Model.Field {
    enum FieldPurpose {
        case email
        case password
        case confirmPassword
    }
    
    enum FieldType {
        case scanServerInfo
        case text(purpose: FieldPurpose)
    }
    
    enum ActionType {
        case hidePassword
        case none
        case scanQr
        case showPassword
    }
}

extension RegisterScene.Model.SceneModel {
    enum State {
        case signIn
        case signUp
        case localAuth
    }
}

// MARK: - Events

extension RegisterScene.Event {
    typealias Model = RegisterScene.Model
    
    // MARK: -
    
    enum ViewDidLoad {
        struct Request {}
    }
    
    enum SetupScene {
        struct Response {
            let sceneModel: Model.SceneModel
        }
        
        struct ViewModel {
            let sceneViewModel: Model.SceneViewModel
        }
    }
    
    enum ScanServerInfoSync {
        struct Request {
            let result: Model.QRCodeReaderResult
        }
        
        enum Response {
            case canceled
            case failed
            case succeeded(sceneModel: Model.SceneModel)
        }
        
        enum ViewModel {
            case canceled
            case failed(errorMessage: String)
            case succeeded(Model.SceneViewModel)
        }
    }
    
    enum FieldEditing {
        struct Request {
            let fieldPurpose: Model.Field.FieldPurpose
            let text: String?
            
            public init(
                fieldPurpose: Model.Field.FieldPurpose,
                text: String?
                ) {
                
                self.fieldPurpose = fieldPurpose
                self.text = text
            }
        }
        typealias Response = ViewModel
        struct ViewModel {
            let fieldPurpose: Model.Field.FieldPurpose
        }
    }
    
    enum FieldShouldReturn {
        struct Request {
            let fieldPurpose: Model.Field.FieldPurpose
        }
        enum Response {
            case focusField(Model.Field.FieldPurpose)
            case resignEditing
        }
        typealias ViewModel = Response
    }
    
    enum SignAction {
        struct Request {}
        
        enum Response {
            case failed(SignError)
            case loaded
            case loading
            case succeededSignIn(account: String)
            case showRecoverySeed(model: RegisterScene.TokenDRegisterWorker.SignUpModel)
        }
        
        enum ViewModel {
            case failed(SignError)
            case loaded
            case loading
            case succeededSignIn(account: String)
            case showRecoverySeed(model: RegisterScene.TokenDRegisterWorker.SignUpModel)
        }
    }
    
    enum SubAction {
        struct Request {
            let subActionIndex: Int
        }
        
        struct Response {
            let action: Action
        }
        
        struct ViewModel {
            let action: Action
        }
    }
    
    enum AgreeOnTerms {
        struct Request {
            let checked: Bool
        }
    }
}

extension RegisterScene.Event.SubAction {
    enum Action {
        case routeToRecovery
        case routeToSignOut
        case routeToSignInAuthenticator
        case showTermsPage(link: URL)
    }
}

extension RegisterScene.Event.SignAction.Response {
    enum SignError {
        case emptyConfirmPassword
        case emptyEmail
        case emptyPassword
        case passwordInvalid(String)
        case passwordsDontMatch
        case signInRequestError(RegisterScene.RegisterWorker.SignInResult.SignError)
        case signUpRequestError(RegisterScene.RegisterWorker.SignUpResult.SignError)
        case termsNotAgreed
    }
}

extension RegisterScene.Event.SignAction.ViewModel {
    struct SignError {
        enum ErrorType {
            case emailAlreadyTaken
            case emailShouldBeVerified(walletId: String)
            case emptyConfirmPassword
            case failedToSaveAccount
            case failedToSaveNetwork
            case otherError
            case passwordInvalid
            case passwordsDontMatch
            case termsNotAgreed
            case tfaFailed
            case wrongEmail
            case wrongPassword
        }
        
        let message: String
        let type: ErrorType
    }
}

extension RegisterScene.Model.Field.FieldType: Equatable {
    
    public static func == (
        lhs: RegisterScene.Model.Field.FieldType,
        rhs: RegisterScene.Model.Field.FieldType
        ) -> Bool {
        
        if case .scanServerInfo = lhs, case .scanServerInfo = rhs {
            return true
        } else if case let .text(lPurpose) = lhs, case let .text(rPurpose) = rhs {
            return lPurpose == rPurpose
        } else {
            return false
        }
    }
}
