import UIKit

protocol RegisterScenePresentationLogic {
    typealias Event = RegisterScene.Event
    
    func presentSetupScene(response: Event.SetupScene.Response)
    func presentScanServerInfoSync(response: Event.ScanServerInfoSync.Response)
    func presentSignAction(response: Event.SignAction.Response)
    func presentSubAction(response: Event.SubAction.Response)
    func presentFieldEditing(response: Event.FieldEditing.Response)
    func presentFieldShouldReturn(response: Event.FieldShouldReturn.Response)
}

extension RegisterScene {
    typealias PresentationLogic = RegisterScenePresentationLogic
    
    struct Presenter {
        
        typealias Event = RegisterScene.Event
        typealias Model = RegisterScene.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        
        // MARK: -
        
        init(presenterDispatch: PresenterDispatch) {
            self.presenterDispatch = presenterDispatch
        }
        
        // MARK: - Private
        
        private func getSceneViewModelForModel(_ sceneModel: Model.SceneModel) -> Model.SceneViewModel {
            let title: String
            let fields = sceneModel.fields.map { (field) -> View.Field in
                return self.getViewFieldForField(field)
            }
            let actionTitle: String
            let subActions = sceneModel.subActions.map { (subAction) -> Model.SubActionViewModel in
                return self.getSubActionViewModel(subAction)
            }
            
            switch sceneModel.state {
                
            case .signIn, .localAuth:
                title = Localized(.sign_in)
                actionTitle = Localized(.signin)
                
            case .signUp:
                title = Localized(.sign_up)
                actionTitle = Localized(.register)
            }
            
            let sceneViewModel = Model.SceneViewModel(
                title: title,
                fields: fields,
                actionTitle: actionTitle,
                subActions: subActions
            )
            
            return sceneViewModel
        }
        
        private func getViewFieldForField(_ field: Model.Field) -> View.Field {
            let title: String
            let text: String? = field.text
            let placeholder: String
            let keyboardType: UIKeyboardType
            let autocapitalize: UITextAutocapitalizationType = .none
            let autocorrection: UITextAutocorrectionType = .no
            let secureInput: Bool
            
            switch field.type {
                
            case .scanServerInfo:
                title = Localized(.server)
                placeholder = Localized(.scan_server_info_qr_code)
                keyboardType = .emailAddress
                secureInput = false
                
            case .text(let purpose):
                switch purpose {
                    
                case .email:
                    title = Localized(.email)
                    placeholder = Localized(.enter_email)
                    keyboardType = .emailAddress
                    secureInput = false
                    
                case .password:
                    title = Localized(.password)
                    placeholder = Localized(.enter_password)
                    keyboardType = .default
                    secureInput = true
                    
                case .confirmPassword:
                    title = Localized(.confirm)
                    placeholder = Localized(.confirm_password)
                    keyboardType = .default
                    secureInput = true
                }
            }
            
            let viewField = View.Field(
                fieldType: field.type,
                title: title,
                text: text,
                placeholder: placeholder,
                keyboardType: keyboardType,
                autocapitalize: autocapitalize,
                autocorrection: autocorrection,
                secureInput: secureInput,
                editable: field.editable
            )
            
            return viewField
        }
        
        private func getSubActionViewModel(_ subAction: Model.SubAction) -> Model.SubActionViewModel {
            switch subAction {
                
            case .recovery:
                return self.getSubActionTextViewModel(
                    plainPart: Localized(.forgot_your_password),
                    actionPart: Localized(.recover_it)
                )
                
            case .signIn:
                return self.getSubActionTextViewModel(
                    plainPart: Localized(.already_have_an_account),
                    actionPart: Localized(.sign_in_now)
                )
                
            case .signUp:
                return self.getSubActionTextViewModel(
                    plainPart: Localized(.dont_have_an_account),
                    actionPart: Localized(.register_now)
                )
                
            case .authenticator:
                return self.getSubActionTextViewModel(
                    plainPart: Localized(.sign_in_via),
                    actionPart: Localized(.authenticator)
                )
                
            case .signOut:
                return self.getSubActionTextViewModel(
                    plainPart: Localized(.erase_all_data_and),
                    actionPart: Localized(.sign_out)
                )
                
            case .agreeOnTerms(let checked, _):
                return .agreeOnTerms(checked: checked)
            }
        }
        
        private func getSubActionTextViewModel(
            plainPart: String,
            actionPart: String
            ) -> Model.SubActionViewModel {
            
            let attributedTitle = NSMutableAttributedString()
            
            attributedTitle.append(NSAttributedString(
                string: plainPart,
                attributes: [
                    NSAttributedString.Key.font: Theme.Fonts.plainTextFont,
                    NSAttributedString.Key.foregroundColor: Theme.Colors.textOnContentBackgroundColor
                ]
            ))
            
            attributedTitle.append(NSAttributedString(
                string: actionPart,
                attributes: [
                    NSAttributedString.Key.font: Theme.Fonts.plainTextFont,
                    NSAttributedString.Key.foregroundColor: Theme.Colors.actionButtonColor,
                    NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
                ]
            ))
            
            return .text(attributedTitle)
        }
        
        private func handleSignAction(response: Event.SignAction.Response) {
            let viewModel: Event.SignAction.ViewModel
            
            switch response {
                
            case .failed(let signError):
                viewModel = self.viewModelForSignError(signError)
                
            case .loaded:
                viewModel = .loaded
                
            case .loading:
                viewModel = .loading
                
            case .succeededSignIn(let account):
                viewModel = .succeededSignIn(account: account)
                
            case .succeededSignUp(let model):
                viewModel = .succeededSignUp(model: model)
            }
            
            self.presenterDispatch.display { (displayLogic) in
                displayLogic.displaySignAction(viewModel: viewModel)
            }
        }
        
        private func viewModelForSignError(
            _ signError: Event.SignAction.Response.SignError
            ) -> Event.SignAction.ViewModel {
            
            typealias SignError = Event.SignAction.ViewModel.SignError
            let error: SignError
            
            switch signError {
                
            case .emptyConfirmPassword:
                error = SignError(
                    message: Localized(.enter_password_confirmation),
                    type: .emptyConfirmPassword
                )
                
            case .emptyEmail:
                error = SignError(
                    message: Localized(.enter_email),
                    type: .wrongEmail
                )
                
            case .emptyPassword:
                error = SignError(
                    message: Localized(.enter_password),
                    type: .wrongPassword
                )
                
            case .passwordInvalid(let message):
                error = SignError(
                    message: message,
                    type: .passwordInvalid
                )
                
            case .passwordsDontMatch:
                error = SignError(
                    message: Localized(.passwords_dont_match),
                    type: .passwordsDontMatch
                )
                
            case .signInRequestError(let requestError):
                error = self.signErrorForSignRequestError(requestError)
                
            case .signUpRequestError(let requestError):
                error = self.signErrorForSignRequestError(requestError)
                
            case .termsNotAgreed:
                error = SignError(
                    message: Localized(.terms_of_service_not_agreed),
                    type: .termsNotAgreed
                )
            }
            
            return .failed(error)
        }
        
        private func signErrorForSignRequestError(
            _ requestError: SignRequestError
            ) -> Event.SignAction.ViewModel.SignError {
            
            typealias SignError = Event.SignAction.ViewModel.SignError
            
            switch requestError {
                
            case .otherError(let error):
                return SignError(message: error.localizedDescription, type: .otherError)
                
            case .wrongEmail:
                return SignError(
                    message: Localized(.wrong_email),
                    type: .wrongEmail
                )
                
            case .wrongPassword:
                return SignError(
                    message: Localized(.wrong_password),
                    type: .wrongPassword
                )
                
            case .emailAlreadyTaken:
                return SignError(
                    message: Localized(.email_already_taken),
                    type: .emailAlreadyTaken
                )
                
            case .failedToSaveAccount:
                return SignError(
                    message: Localized(.failed_to_save_account_data),
                    type: .failedToSaveAccount
                )
                
            case .failedToSaveNetwork:
                return SignError(
                    message: Localized(.failed_to_save_network_info),
                    type: .failedToSaveNetwork
                )
                
            case .emailShouldBeVerified(let walletId):
                return SignError(
                    message: Localized(.email_address_is_not_verified),
                    type: .emailShouldBeVerified(walletId: walletId)
                )
                
            case .tfaFailed:
                return SignError(
                    message: Localized(.twofactor_authentication_failed),
                    type: .tfaFailed
                )
            }
        }
    }
}

extension RegisterScene.Presenter: RegisterScene.PresentationLogic {
    func presentSetupScene(response: Event.SetupScene.Response) {
        let sceneViewModel = self.getSceneViewModelForModel(response.sceneModel)
        let viewModel = Event.SetupScene.ViewModel(sceneViewModel: sceneViewModel)
        self.presenterDispatch.display { displayLogic in
            displayLogic.displaySetupScene(viewModel: viewModel)
        }
    }
    
    func presentScanServerInfoSync(response: Event.ScanServerInfoSync.Response) {
        let viewModel: Event.ScanServerInfoSync.ViewModel
        switch response {
        case .canceled:
            viewModel = .canceled
            
        case .failed:
            viewModel = .failed(errorMessage: Localized(.failed_to_scan_server_info))
            
        case .succeeded(let sceneModel):
            let sceneViewModel = self.getSceneViewModelForModel(sceneModel)
            viewModel = .succeeded(sceneViewModel)
        }
        
        self.presenterDispatch.displaySync { displayLogic in
            displayLogic.displayScanServerInfoSync(viewModel: viewModel)
        }
    }
    
    func presentSignAction(response: Event.SignAction.Response) {
        self.handleSignAction(response: response)
    }
    
    func presentSubAction(response: Event.SubAction.Response) {
        let viewModel = Event.SubAction.ViewModel(action: response.action)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySubAction(viewModel: viewModel)
        }
    }
    
    func presentFieldEditing(response: Event.FieldEditing.Response) {
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayFieldEditing(viewModel: viewModel)
        }
    }
    
    func presentFieldShouldReturn(response: Event.FieldShouldReturn.Response) {
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayFieldShouldReturn(viewModel: viewModel)
        }
    }
}
