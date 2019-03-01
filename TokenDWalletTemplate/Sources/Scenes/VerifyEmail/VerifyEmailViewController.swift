import UIKit
import RxCocoa
import RxSwift

protocol VerifyEmailDisplayLogic: class {
    func displayResendEmail(viewModel: VerifyEmail.Event.ResendEmail.ViewModel)
    func displayVerifyToken(viewModel: VerifyEmail.Event.VerifyToken.ViewModel)
}

extension VerifyEmail {
    typealias DisplayLogic = VerifyEmailDisplayLogic
    
    class ViewController: UIViewController {
        
        // MARK: - Private properties
        
        let marginInset: CGFloat = 20.0
        
        private let messageLabel: UILabel = UILabel()
        private let resendButton: UIButton = UIButton(type: .custom)
        
        private let disposeBag = DisposeBag()
        
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
            
            self.view.backgroundColor = Theme.Colors.contentBackgroundColor
            
            self.setupMessageLabel()
            self.setupResendButton()
            self.setupLayout()
            
            let request = VerifyEmail.Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                businessLogic.onViewDidLoad(request: request)
            })
        }
        
        // MARK: - Actions
        
        func onResendEmailAction() {
            let request = Event.ResendEmail.Request()
            self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                businessLogic.onResendEmail(request: request)
            })
        }
        
        // MARK: - Private
        
        private func setupMessageLabel() {
            self.messageLabel.font = Theme.Fonts.largeTitleFont
            self.messageLabel.textColor = Theme.Colors.textOnContentBackgroundColor
            self.messageLabel.textAlignment = .center
            self.messageLabel.numberOfLines = 0
            self.messageLabel.text = Localized(.verification_link_is_sent)
        }
        
        private func setupResendButton() {
            SharedViewsBuilder.configureActionButton(self.resendButton, title: Localized(.resend_email))
            self.resendButton
                .rx
                .controlEvent(.touchUpInside)
                .asDriver()
                .drive(onNext: { [weak self] in
                    self?.onResendEmailAction()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupLayout() {
            self.view.addSubview(self.messageLabel)
            self.view.addSubview(self.resendButton)
            
            self.messageLabel.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(self.marginInset)
                make.top.equalTo(self.view.snp.bottom).multipliedBy(0.3)
            }
            
            self.resendButton.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(self.marginInset)
                make.bottom.equalTo(self.view.safeArea.bottom).inset(self.marginInset)
                make.height.equalTo(44.0)
            }
        }
    }
}

// MARK: - VerifyEmailDisplayLogic
extension VerifyEmail.ViewController: VerifyEmail.DisplayLogic {
    func displayResendEmail(viewModel: VerifyEmail.Event.ResendEmail.ViewModel) {
        switch viewModel {
            
        case .failed(let errorMessage):
            self.routing?.showErrorMessage(errorMessage)
            
        case .loaded:
            self.routing?.hideProgress()
            
        case .loading:
            self.routing?.showProgress()
        }
    }
    
    func displayVerifyToken(viewModel: VerifyEmail.Event.VerifyToken.ViewModel) {
        switch viewModel {
            
        case .failed(let errorMessage):
            self.routing?.showErrorMessage(errorMessage)
            
        case .loaded:
            self.routing?.hideProgress()
            
        case .loading:
            self.routing?.showProgress()
            
        case .succeded:
            self.routing?.onEmailVerified()
        }
    }
}
