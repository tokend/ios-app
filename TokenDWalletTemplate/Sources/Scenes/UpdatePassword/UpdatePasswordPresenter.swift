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
                    case .email: return Localized(.email_lowercased)
                    case .seed: return Localized(.recovery_seed_lowercased)
                    case .oldPassword: return Localized(.old_password_lowercased)
                    case .newPassword: return Localized(.new_password_lowercased)
                    case .confirmPassword: return Localized(.confirm_password_lowercased)
                    }
                }()
                error = SubmitError(
                    message: Localized(
                        .enter_f,
                        replace: [
                            .enter_f_replace_field_name: fieldName
                        ]
                    ),
                    error: submitActionError
                )
                
            case .incorrectSeed:
                error = SubmitError(
                    message: Localized(.incorrect_or_corrupted_recovery_seed),
                    error: submitActionError
                )
                
            case .passwordInvalid(let message):
                error = SubmitError(
                    message: message,
                    error: submitActionError
                )
                
            case .passwordsDontMatch:
                error = SubmitError(
                    message: Localized(.passwords_dont_match),
                    error: submitActionError
                )
                
            case .submitError(let submitError):
                error = SubmitError(
                    message: submitError.localizedDescription,
                    error: submitActionError
                )
                
            case .networkInfoFetchFailed:
                error = SubmitError(
                    message: Localized(.failed_to_fetch_network_info),
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
        case .email: return Localized(.email)
        case .seed: return Localized(.recovery_seed)
        case .oldPassword: return Localized(.old_password)
        case .newPassword: return Localized(.new_password)
        case .confirmPassword: return Localized(.confirm_password)
        }
    }
    
    var viewModelPlaceholder: String {
        switch self {
        case .confirmPassword:
            return Localized(.confirm_new_password)
        default:
            let title = self.viewModelTitle
            return Localized(
                .enter_t,
                replace: [
                    .enter_t_replace_title: title
                ]
            )
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
