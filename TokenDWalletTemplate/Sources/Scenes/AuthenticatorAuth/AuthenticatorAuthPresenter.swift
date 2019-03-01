import UIKit

protocol AuthenticatorAuthPresentationLogic {
    typealias Event = AuthenticatorAuth.Event
    
    func presentActionButtonClicked(response: Event.ActionButtonClicked.Response)
    func presentSetupActionButton(response: Event.SetupActionButton.Resposne)
    func presentUpdateQRContent(response: Event.UpdateQRContent.Response)
    func presentFetchedAuthResult(response: Event.FetchedAuthResult.Response)
}

extension AuthenticatorAuth {
    typealias PresentationLogic = AuthenticatorAuthPresentationLogic
    
    class Presenter {
        
        typealias Event = AuthenticatorAuth.Event
        typealias Model = AuthenticatorAuth.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        private let qrCodeGenerator: AuthRequestQRCodeGeneratorProtocol
        
        // MARK: -
        
        init(
            presenterDispatch: PresenterDispatch,
            qrCodeGenerator: AuthRequestQRCodeGeneratorProtocol
            ) {
            
            self.presenterDispatch = presenterDispatch
            self.qrCodeGenerator = qrCodeGenerator
        }
    }
}

extension AuthenticatorAuth.Presenter: AuthenticatorAuth.PresentationLogic {
    
    func presentActionButtonClicked(response: Event.ActionButtonClicked.Response) {
        let viewModel = Event.ActionButtonClicked.ViewModel(url: response.url)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayActionButtonClicked(viewModel: viewModel)
        }
    }
    
    func presentSetupActionButton(response: Event.SetupActionButton.Resposne) {
        let state: Model.AuthAppStateViewModel = {
            switch response.state {
                
            case .cantInstall:
                return .inaccessable
                
            case .installed:
                return .accessable(Localized(.sign_in_with_authenticator))
                
            case .notInstalled:
                return .accessable(Localized(.install_authenticator))
            }
        }()
        
        let viewModel = Event.SetupActionButton.ViewModel(state: state)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySetupActionButton(viewModel: viewModel)
        }
    }
    
    func presentUpdateQRContent(response: Event.UpdateQRContent.Response) {
        guard let authRequest = response.url else {
            return
        }
        self.qrCodeGenerator.generateQRCodeFromString(
            authRequest.absoluteString,
            withTintColor: UIColor.black,
            backgroundColor: UIColor.clear,
            size: response.qrSize,
            completion: { [weak self] (image) in
                guard let image = image else {
                    return
                }
                
                let viewModel = Event.UpdateQRContent.ViewModel(qrImage: image)
                self?.presenterDispatch.display(displayBlock: { (displayLogic) in
                    displayLogic.displayUpdateQRContent(viewModel: viewModel)
                })
        })
    }
    
    func presentFetchedAuthResult(response: Event.FetchedAuthResult.Response) {
        let viewModel = Event.FetchedAuthResult.ViewModel(result: response.result)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayFetchedAuthResult(viewModel: viewModel)
        }
    }
}
