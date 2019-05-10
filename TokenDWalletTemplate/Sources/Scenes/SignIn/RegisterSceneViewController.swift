import UIKit

protocol RegisterSceneDisplayLogic: class {
    typealias Event = RegisterScene.Event
    
    func displaySetupScene(viewModel: Event.SetupScene.ViewModel)
    func displayScanServerInfoSync(viewModel: Event.ScanServerInfoSync.ViewModel)
    func displaySignAction(viewModel: Event.SignAction.ViewModel)
    func displaySubAction(viewModel: Event.SubAction.ViewModel)
    func displayFieldEditing(viewModel: Event.FieldEditing.ViewModel)
    func displayFieldShouldReturn(viewModel: Event.FieldShouldReturn.ViewModel)
}

extension RegisterScene {
    typealias DisplayLogic = RegisterSceneDisplayLogic
    
    class ViewController: UIViewController {
        
        typealias Event = RegisterScene.Event
        typealias Model = RegisterScene.Model
        
        // MARK: - Private property
        
        private let signInView: View = View()
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        
        func inject(interactorDispatch: InteractorDispatch?, routing: Routing?) {
            self.interactorDispatch = interactorDispatch
            self.routing = routing
        }
        
        // MARK: - Overridden
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.setupView()
            self.setupLayout()
            
            let request = Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.signInView.onScanQRAction = { [weak self] in
                self?.routing?.onPresentQRCodeReader({ (result) in
                    let request = Event.ScanServerInfoSync.Request(result: result)
                    self?.interactorDispatch?.sendSyncRequest(requestBlock: { (businessLogic) in
                        businessLogic.onScanServerInfoSync(request: request)
                    })
                })
            }
            self.signInView.onEditField = { [weak self] fieldPurpose, text in
                let request = Event.FieldEditing.Request(
                    fieldPurpose: fieldPurpose,
                    text: text
                )
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onFieldEditing(request: request)
                })
            }
            self.signInView.onFieldShouldReturn = { [weak self] fieldPurpose in
                let request = Event.FieldShouldReturn.Request(
                    fieldPurpose: fieldPurpose
                )
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onFieldShouldReturn(request: request)
                })
            }
            self.signInView.onActionButton = { [weak self] in
                let request = Event.SignAction.Request()
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onSignAction(request: request)
                })
            }
            self.signInView.onSubActionButton = { [weak self] index in
                let request = Event.SubAction.Request(subActionIndex: index)
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onSubAction(request: request)
                })
            }
            self.signInView.onAgreeOnTerms = { [weak self] (checked) in
                let request = Event.AgreeOnTerms.Request(checked: checked)
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onAgreeOnTerms(request: request)
                })
            }
        }
        
        private func setupLayout() {
            self.view.addSubview(self.signInView)
            self.signInView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
        
        private func applySceneViewModel(_ sceneViewModel: Model.SceneViewModel) {
            self.navigationItem.backBarButtonItem = UIBarButtonItem(
                title: sceneViewModel.title,
                style: .plain,
                target: nil,
                action: nil
            )
            self.signInView.set(
                title: sceneViewModel.title,
                fields: sceneViewModel.fields,
                actionTitle: sceneViewModel.actionTitle,
                subActions: sceneViewModel.subActions
            )
        }
        
        private func focusFields(_ fields: [Model.Field.FieldPurpose]) {
            for purpose in fields {
                self.signInView.showErrorForField(purpose)
            }
        }
        
        private func unfocusFields(_ fields: [Model.Field.FieldPurpose]) {
            for purpose in fields {
                self.signInView.hideErrorForField(purpose)
            }
        }
        
        private func switchToField(_ fieldPurpose: Model.Field.FieldPurpose) {
            self.signInView.switchToField(fieldPurpose)
        }
        
        private func resignEditing() {
            self.view.endEditing(true)
        }
        
        private func handleSignError(_ error: Event.SignAction.ViewModel.SignError) {
            switch error.type {
                
            case .emailAlreadyTaken:
                self.focusFields([.email])
                
            case .emailShouldBeVerified(let walletId):
                self.routing?.onUnverifiedEmail(walletId)
                
            case .emptyConfirmPassword:
                self.focusFields([.confirmPassword])
                
            case .passwordInvalid:
                self.focusFields([.password])
                
            case .passwordsDontMatch:
                self.focusFields([.password, .confirmPassword])
                
            case .wrongEmail:
                self.focusFields([.email])
                
            case .wrongPassword:
                self.focusFields([.password])
                
            case .failedToSaveAccount,
                 .failedToSaveNetwork,
                 .otherError,
                 .tfaFailed,
                 .termsNotAgreed:
                // ignore
                break
            }
        }
    }
}

extension RegisterScene.ViewController: RegisterScene.DisplayLogic {
    func displaySetupScene(viewModel: Event.SetupScene.ViewModel) {
        self.applySceneViewModel(viewModel.sceneViewModel)
    }
    
    func displayScanServerInfoSync(viewModel: Event.ScanServerInfoSync.ViewModel) {
        switch viewModel {
            
        case .canceled:
            break
            
        case .failed(let errorMessage):
            self.routing?.showErrorMessage(errorMessage, nil)
            
        case .succeeded(let sceneViewModel):
            self.applySceneViewModel(sceneViewModel)
        }
    }
    
    func displaySignAction(viewModel: Event.SignAction.ViewModel) {
        switch viewModel {
            
        case .loading:
            self.routing?.showProgress()
            
        case .loaded:
            self.routing?.hideProgress()
            
        case .failed(let error):
            self.routing?.showErrorMessage(error.message, nil)
            self.handleSignError(error)
            
        case .succeededSignIn(let account):
            self.routing?.onSuccessfulLogin(account)
            
        case .showRecoverySeed(let model):
            self.routing?.onShowRecoverySeed(model)
        }
    }
    
    func displaySubAction(viewModel: Event.SubAction.ViewModel) {
        switch viewModel.action {
            
        case .routeToRecovery:
            self.routing?.onRecovery()
            
        case .routeToSignInAuthenticator:
            self.routing?.onAuthenticatorSignIn()
            
        case .routeToSignOut:
            self.routing?.onSignedOut()
            
        case .showTermsPage(let link):
            self.routing?.onShowTerms(link)
        }
    }
    
    func displayFieldEditing(viewModel: Event.FieldEditing.ViewModel) {
        self.unfocusFields([viewModel.fieldPurpose])
    }
    
    func displayFieldShouldReturn(viewModel: Event.FieldShouldReturn.ViewModel) {
        switch viewModel {
            
        case .focusField(let purpose):
            self.switchToField(purpose)
            
        case .resignEditing:
            self.resignEditing()
        }
    }
}
