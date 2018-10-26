import UIKit

protocol UpdatePasswordPresentationLogic {
    func presentViewDidLoadSync(response: UpdatePassword.Event.ViewDidLoadSync.Response)
    func presentSubmitAction(response: UpdatePassword.Event.SubmitAction.Response)
}

extension UpdatePassword {
    typealias PresentationLogic = UpdatePasswordPresentationLogic
    
    struct Presenter {
        
        private let presenterDispatch: PresenterDispatch
        
        init(presenterDispatch: PresenterDispatch) {
            self.presenterDispatch = presenterDispatch
        }
        
        // MARK: - Private
        
        private func getFieldViewModels(
            _ fields: [Model.Field]
            ) -> [View.Field] {
            
            let fieldViewModels = fields.map { (field) -> View.Field in
                let fieldViewModel = View.Field(
                    fieldType: field.type,
                    title: field.type.viewModelTitle,
                    text: field.value,
                    placeholder: field.type.viewModelPlaceholder,
                    keyboardType: field.type.viewModelKeyboardType,
                    autocapitalize: .none,
                    autocorrection: .no,
                    secureInput: field.type.viewModelIsSecureInput
                )
                
                return fieldViewModel
            }
            
            return fieldViewModels
        }
        
        private func getSubmitActionErrorViewModel(
            _ submitActionError: Event.SubmitAction.Response.ErrorModel
            ) -> Event.SubmitAction.ViewModel.ErrorViewModel {
            
            typealias SubmitError = Event.SubmitAction.ViewModel.ErrorViewModel
            let error: SubmitError
            
            switch submitActionError {
                
            case .emptyField(let fieldType):
                let fieldName: String = {
                    switch fieldType {
                    case .email: return "email"
                    case .seed: return "recovery seeed"
                    case .oldPassword: return "old password"
                    case .newPassword: return "new password"
                    case .confirmPassword: return "confirm password"
                    }
                }()
                error = SubmitError(
                    message: "Enter \(fieldName)",
                    error: submitActionError
                )
                
            case .incorrectSeed:
                error = SubmitError(
                    message: "Incorrect or corrupted recovery seed",
                    error: submitActionError
                )
                
            case .passwordsDontMatch:
                error = SubmitError(
                    message: "Passwords don't match",
                    error: submitActionError
                )
                
            case .submitError(let submitError):
                error = SubmitError(
                    message: submitError.localizedDescription,
                    error: submitActionError
                )
                
            case .networkInfoFetchFailed:
                error = SubmitError(
                    message: "Failed to fetch network info",
                    error: submitActionError
                )
            }
            
            return error
        }
    }
}

extension UpdatePassword.Presenter: UpdatePassword.PresentationLogic {
    func presentViewDidLoadSync(response: UpdatePassword.Event.ViewDidLoadSync.Response) {
        let viewModel = UpdatePassword.Event.ViewDidLoadSync.ViewModel(
            fields: self.getFieldViewModels(response.fields)
        )
        self.presenterDispatch.displaySync { displayLogic in
            displayLogic.displayViewDidLoadSync(viewModel: viewModel)
        }
    }
    
    func presentSubmitAction(response: UpdatePassword.Event.SubmitAction.Response) {
        let viewModel: UpdatePassword.Event.SubmitAction.ViewModel
        
        switch response {
        case .loaded:
            viewModel = .loaded
            
        case .loading:
            viewModel = .loading
            
        case .succeeded:
            viewModel = .succeeded
            
        case .failed(let error):
            viewModel = .failed(self.getSubmitActionErrorViewModel(error))
        }
        
        self.presenterDispatch.display { displayLogic in
            displayLogic.displaySubmitAction(viewModel: viewModel)
        }
    }
}

extension UpdatePassword.Model.FieldType {
    var viewModelTitle: String {
        switch self {
        case .email: return "Email"
        case .seed: return "Recovery seed"
        case .oldPassword: return "Old Password"
        case .newPassword: return "New Password"
        case .confirmPassword: return "Confirm"
        }
    }
    
    var viewModelPlaceholder: String {
        switch self {
        case .confirmPassword:
            return "Confirm New Password"
        default:
            return "Enter \(self.viewModelTitle)"
        }
    }
    
    var viewModelKeyboardType: UIKeyboardType {
        switch self {
        case .email:
            return .emailAddress
        default:
            return .default
        }
    }
    
    var viewModelIsSecureInput: Bool {
        switch self {
        case .oldPassword,
             .newPassword,
             .confirmPassword:
            return true
            
        default:
            return false
        }
    }
}
