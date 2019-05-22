import Foundation

protocol RegisterSceneBusinessLogic {
    typealias Event = RegisterScene.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onScanServerInfoSync(request: Event.ScanServerInfoSync.Request)
    func onFieldEditing(request: Event.FieldEditing.Request)
    func onFieldShouldReturn(request: Event.FieldShouldReturn.Request)
    func onSignAction(request: Event.SignAction.Request)
    func onSubAction(request: Event.SubAction.Request)
    func onAgreeOnTerms(request: Event.AgreeOnTerms.Request)
}

extension RegisterScene {
    typealias BusinessLogic = RegisterSceneBusinessLogic
    typealias RegisterWorker = RegisterSceneSignInWorkerProtocol
        & RegisterSceneSignUpWorkerProtocol
        & RegisterSceneSignOutWorkerProtocol
    
    class Interactor {
        
        typealias Event = RegisterScene.Event
        typealias Model = RegisterScene.Model
        
        // MARK: - Private properties
        
        private var sceneModel: Model.SceneModel
        
        private let presenter: PresentationLogic
        private let registerWorker: RegisterWorker
        private let passwordValidator: PasswordValidatorProtocol
        
        // MARK: -
        
        init(
            presenter: PresentationLogic,
            sceneModel: Model.SceneModel,
            registerWorker: RegisterWorker,
            passwordValidator: PasswordValidatorProtocol
            ) {
            
            self.presenter = presenter
            self.sceneModel = sceneModel
            self.registerWorker = registerWorker
            self.passwordValidator = passwordValidator
        }
        
        // MARK: - Private
        
        private func setupSignInState() {
            let serverField = Model.Field(
                type: .scanServerInfo,
                text: self.registerWorker.getServerInfoTitle(),
                editable: false
            )
            let emailField = Model.Field(
                type: .text(purpose: .email),
                text: self.getEmail()
            )
            let passwordField = Model.Field(
                type: .text(purpose: .password),
                text: nil
            )
            
            self.sceneModel = Model.SceneModel(
                state: .signIn,
                fields: [serverField, emailField, passwordField],
                subActions: [.signUp, .recovery],
                termsUrl: self.sceneModel.termsUrl
            )
        }
        
        private func setupSignUpState() {
            let serverField = Model.Field(
                type: .scanServerInfo,
                text: self.registerWorker.getServerInfoTitle(),
                editable: false
            )
            let emailField = Model.Field(
                type: .text(purpose: .email),
                text: self.getEmail()
            )
            let passwordField = Model.Field(
                type: .text(purpose: .password),
                text: nil
            )
            let confirmPasswordField = Model.Field(
                type: .text(purpose: .confirmPassword),
                text: nil
            )
            
            var subActions: [Model.SubAction] = [.signIn]
            if let termsUrl = self.sceneModel.termsUrl {
                subActions.append(.agreeOnTerms(checked: false, link: termsUrl))
            }
            
            self.sceneModel = Model.SceneModel(
                state: .signUp,
                fields: [serverField, emailField, passwordField, confirmPasswordField],
                subActions: subActions,
                termsUrl: self.sceneModel.termsUrl
            )
        }
        
        private func setupLocalAuthState() {
            let emailField = Model.Field(
                type: .text(purpose: .email),
                text: self.getEmail(),
                editable: false
            )
            let passwordField = Model.Field(
                type: .text(purpose: .password),
                text: nil
            )
            
            self.sceneModel = Model.SceneModel(
                state: .signIn,
                fields: [emailField, passwordField],
                subActions: [.recovery, .signOut],
                termsUrl: self.sceneModel.termsUrl
            )
        }
        
        private func getTextFieldValue(purpose: Model.Field.FieldPurpose) -> String? {
            for field in self.sceneModel.fields {
                switch field.type {
                    
                case .scanServerInfo:
                    continue
                    
                case .text(let fieldPurpose):
                    if fieldPurpose == purpose {
                        return field.text
                    }
                }
            }
            return nil
        }
        
        private func getEmail() -> String? {
            return self.getTextFieldValue(purpose: .email)
        }
        
        private func getPassword() -> String? {
            return self.getTextFieldValue(purpose: .password)
        }
        
        private func getConfirmPassword() -> String? {
            return self.getTextFieldValue(purpose: .confirmPassword)
        }
        
        private func getTermsAgreed() -> Bool {
            for subAction in self.sceneModel.subActions {
                switch subAction {
                    
                case .agreeOnTerms(let checked, _):
                    return checked
                    
                default:
                    break
                }
            }
            
            return true
        }
        
        private func handleScanQRCodeValue(_ value: String) {
            let result = self.registerWorker.handleServerInfoQRScannedString(value)
            
            let response: Event.ScanServerInfoSync.Response
            switch result {
                
            case .failure:
                response = .failed
                
            case .success:
                self.updateServerInfoField()
                response = .succeeded(sceneModel: self.sceneModel)
            }
            self.presenter.presentScanServerInfoSync(response: response)
        }
        
        private func updateServerInfoField() {
            guard let serverInfoField = self.sceneModel.fields.first(where: { (field) -> Bool in
                switch field.type {
                    
                case .scanServerInfo:
                    return true
                    
                case .text:
                    return false
                }
            }) else {
                return
            }
            
            serverInfoField.text = self.registerWorker.getServerInfoTitle()
        }
        
        private func handleSignAction() {
            switch self.sceneModel.state {
                
            case .signIn, .localAuth:
                self.performSignIn()
                
            case .signUp:
                self.performSignUp()
            }
        }
        
        private func performSignIn() {
            guard let email = self.getEmail(), email.count > 0 else {
                let response: Event.SignAction.Response = .failed(.emptyEmail)
                self.presenter.presentSignAction(response: response)
                return
            }
            
            guard let password = self.getPassword(), password.count > 0 else {
                let response: Event.SignAction.Response = .failed(.emptyPassword)
                self.presenter.presentSignAction(response: response)
                return
            }
            
            self.presenter.presentSignAction(response: .loading)
            self.registerWorker.performSignInRequest(
                email: email,
                password: password,
                completion: { [weak self] result in
                    
                    self?.presenter.presentSignAction(response: .loaded)
                    
                    switch result {
                        
                    case .failed(let error):
                        self?.presenter.presentSignAction(response: .failed(.signInRequestError(error)))
                        
                    case .succeeded(let account):
                        self?.presenter.presentSignAction(response: .succeededSignIn(account: account))
                    }
            })
        }
        
        private func performSignUp() {
            guard let email = self.getEmail(), email.count > 0 else {
                let response: Event.SignAction.Response = .failed(.emptyEmail)
                self.presenter.presentSignAction(response: response)
                return
            }
            
            guard let password = self.getPassword(), password.count > 0 else {
                let response: Event.SignAction.Response = .failed(.emptyPassword)
                self.presenter.presentSignAction(response: response)
                return
            }
            
            let passwordValidationResult = self.passwordValidator.validate(password: password)
            switch passwordValidationResult {
                
            case .error(let message):
                let response: Event.SignAction.Response = .failed(.passwordInvalid(message))
                self.presenter.presentSignAction(response: response)
                return
                
            default:
                break
            }
            
            guard let confirmPassword = self.getConfirmPassword(), confirmPassword.count > 0 else {
                let response: Event.SignAction.Response = .failed(.emptyConfirmPassword)
                self.presenter.presentSignAction(response: response)
                return
            }
            
            guard password == confirmPassword else {
                let response: Event.SignAction.Response = .failed(.passwordsDontMatch)
                self.presenter.presentSignAction(response: response)
                return
            }
            
            guard self.getTermsAgreed() else {
                let response: Event.SignAction.Response = .failed(.termsNotAgreed)
                self.presenter.presentSignAction(response: response)
                return
            }
            
            self.presenter.presentSignAction(response: .loading)
            self.registerWorker.performSignUpRequest(
                email: email,
                password: password,
                completion: { [weak self] result in
                    self?.presenter.presentSignAction(response: .loaded)
                    
                    switch result {
                        
                    case .failed(let error):
                        self?.presenter.presentSignAction(response: .failed(.signUpRequestError(error)))
                        
                    case .succeeded(let model):
                        self?.presenter.presentSignAction(response: .showRecoverySeed(model: model))
                    }
            })
        }
    }
}

extension RegisterScene.Interactor: RegisterScene.BusinessLogic {
    func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        switch self.sceneModel.state {
            
        case .localAuth:
            self.setupLocalAuthState()
            
        case .signIn:
            self.setupSignInState()
            
        case .signUp:
            self.setupSignUpState()
        }
        
        let response = Event.SetupScene.Response(sceneModel: self.sceneModel)
        self.presenter.presentSetupScene(response: response)
    }
    
    func onScanServerInfoSync(request: Event.ScanServerInfoSync.Request) {
        let response: Event.ScanServerInfoSync.Response
        switch request.result {
            
        case .canceled:
            response = .canceled
            
        case .success(let value, _):
            self.handleScanQRCodeValue(value)
            return
        }
        
        self.presenter.presentScanServerInfoSync(response: response)
    }
    
    func onFieldEditing(request: Event.FieldEditing.Request) {
        for (index, field) in self.sceneModel.fields.enumerated() {
            switch field.type {
                
            case .scanServerInfo:
                break
                
            case .text(let purpose):
                if purpose == request.fieldPurpose {
                    self.sceneModel.fields[index].text = request.text
                }
            }
        }
        
        let response = Event.FieldEditing.Response(
            fieldPurpose: request.fieldPurpose
        )
        self.presenter.presentFieldEditing(response: response)
    }
    
    func onFieldShouldReturn(request: Event.FieldShouldReturn.Request) {
        guard let fieldIndex = self.sceneModel.fields.index(where: { (field) -> Bool in
            switch field.type {
                
            case .scanServerInfo:
                return false
                
            case .text(let purpose):
                return purpose == request.fieldPurpose
            }
        }) else {
            return
        }
        
        let lastFieldIndex = self.sceneModel.fields.endIndex - 1
        guard fieldIndex < lastFieldIndex else {
            self.handleSignAction()
            self.presenter.presentFieldShouldReturn(response: .resignEditing)
            return
        }
        
        var nextField: Model.Field.FieldPurpose?
        for nextFieldIndex in fieldIndex.advanced(by: 1)...lastFieldIndex {
            let field = self.sceneModel.fields[nextFieldIndex]
            switch field.type {
                
            case .scanServerInfo:
                continue
                
            case .text(let purpose):
                nextField = purpose
            }
        }
        
        let response: Event.FieldShouldReturn.Response
        if let nextFieldPurpose = nextField {
            response = .focusField(nextFieldPurpose)
        } else {
            response = .resignEditing
            self.handleSignAction()
        }
        
        self.presenter.presentFieldShouldReturn(response: response)
    }
    
    func onSignAction(request: Event.SignAction.Request) {
        self.handleSignAction()
    }
    
    func onSubAction(request: Event.SubAction.Request) {
        let subAction = self.sceneModel.subActions[request.subActionIndex]
        
        switch subAction {
            
        case .recovery:
            let response = Event.SubAction.Response(action: .routeToRecovery)
            self.presenter.presentSubAction(response: response)
            
        case .signIn:
            self.setupSignInState()
            
            let response = Event.SetupScene.Response(sceneModel: self.sceneModel)
            self.presenter.presentSetupScene(response: response)
            
        case .signUp:
            self.setupSignUpState()
            
            let response = Event.SetupScene.Response(sceneModel: self.sceneModel)
            self.presenter.presentSetupScene(response: response)
            
        case .signOut:
            let response = Event.SubAction.Response(action: .routeToSignOut)
            self.presenter.presentSubAction(response: response)
            
        case .agreeOnTerms(_, let link):
            let response = Event.SubAction.Response(action: .showTermsPage(link: link))
            self.presenter.presentSubAction(response: response)
            
        case .authenticator:
            let response = Event.SubAction.Response(action: .routeToSignInAuthenticator)
            self.presenter.presentSubAction(response: response)
        }
    }
    
    func onAgreeOnTerms(request: Event.AgreeOnTerms.Request) {
        for (index, subAction) in self.sceneModel.subActions.enumerated() {
            switch subAction {
                
            case .agreeOnTerms(_, let link):
                self.sceneModel.subActions[index] = .agreeOnTerms(checked: request.checked, link: link)
                
            case .recovery, .signIn, .signOut, .signUp, .authenticator:
                break
            }
        }
    }
}
