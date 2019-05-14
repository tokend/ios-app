import UIKit
import RxCocoa
import RxSwift

protocol RecoverySeedDisplayLogic: class {
    func displayViewDidLoad(viewModel: RecoverySeed.Event.ViewDidLoad.ViewModel)
    func displayValidationSeedEditing(viewModel: RecoverySeed.Event.ValidationSeedEditing.ViewModel)
    func displayCopyAction(viewModel: RecoverySeed.Event.CopyAction.ViewModel)
    func displayShowWarning(viewModel: RecoverySeed.Event.ShowWarning.ViewModel)
    func displaySignUpAction(viewModel: RecoverySeed.Event.SignUpAction.ViewModel)
}

extension RecoverySeed {
    typealias DisplayLogic = RecoverySeedDisplayLogic
    
    class ViewController: UIViewController {
        
        // MARK: - Private properties
        
        private let messageLabel: UILabel = UILabel()
        private let validateTitleLabel: UILabel = UILabel()
        private var seedEditingContext: TextEditingContext<String>?
        private let textFieldView: TextFieldView = TextFieldView()
        private let inputSeedValidImage: UIImageView = UIImageView()
        private let copyButton: UIButton = UIButton(type: .custom)
        
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
            
            self.setupView()
            self.setupMessageLabel()
            self.setupValidateTitleLabel()
            self.setupTextFieldView()
            self.setupInputSeedValidImage()
            self.setupCopyButton()
            self.setupProceedButton()
            self.setupLayout()
            
            let request = RecoverySeed.Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupMessageLabel() {
            self.messageLabel.font = Theme.Fonts.plainTextFont
            self.messageLabel.textColor = Theme.Colors.textOnContentBackgroundColor
            self.messageLabel.textAlignment = .left
            self.messageLabel.numberOfLines = 0
            self.messageLabel.text = Localized(.save_this_seed_to_x)
        }
        
        private func setupValidateTitleLabel() {
            self.validateTitleLabel.font = Theme.Fonts.plainTextFont
            self.validateTitleLabel.textColor = Theme.Colors.textOnContentBackgroundColor
            self.validateTitleLabel.textAlignment = .left
            self.validateTitleLabel.numberOfLines = 0
            self.validateTitleLabel.text = Localized(.please_validate_this_seed)
        }
        
        private func setupTextFieldView() {
            self.textFieldView.placeholder = Localized(.enter_recovery_seed)
            self.textFieldView.autocapitalizationType = .none
            self.textFieldView.autocorrectionType = .no
            
            self.seedEditingContext = TextEditingContext(
                textInputView: self.textFieldView,
                valueFormatter: PlainTextValueFormatter(),
                callbacks: TextEditingContext.Callbacks(
                    onInputValue: { [weak self] value in
                        let request = Event.ValidationSeedEditing.Request(value: value)
                        self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                            businessLogic.onValidationSeedEditing(request: request)
                        })
                })
            )
        }
        
        private func setupInputSeedValidImage() {
            self.inputSeedValidImage.image = #imageLiteral(resourceName: "Checkmark")
            self.inputSeedValidImage.contentMode = .scaleAspectFit
            self.updateInputSeedValid(.empty)
        }
        
        private func setupCopyButton() {
            SharedViewsBuilder.configureActionButton(self.copyButton, title: Localized(.copy))
            self.copyButton
                .rx
                .controlEvent(.touchUpInside)
                .asDriver()
                .drive(onNext: { [weak self] in
                    self?.view.endEditing(true)
                    
                    let request = Event.CopyAction.Request()
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onCopyAction(request: request)
                    })
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupProceedButton() {
            let button = UIBarButtonItem(image: #imageLiteral(resourceName: "Checkmark"), style: .plain, target: nil, action: nil)
            button.rx
                .tap
                .asDriver()
                .drive(onNext: { [weak self] in
                    self?.view.endEditing(true)
                    
                    let request = Event.ProceedAction.Request()
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onProceedAction(request: request)
                    })
                })
                .disposed(by: self.disposeBag)
            self.navigationItem.rightBarButtonItem = button
        }
        
        private func setupLayout() {
            let topSeparator = UIView()
            self.setupSeparator(topSeparator)
            let bottomSeparator = UIView()
            self.setupSeparator(bottomSeparator)
            
            self.view.addSubview(self.messageLabel)
            self.view.addSubview(self.validateTitleLabel)
            self.view.addSubview(topSeparator)
            self.view.addSubview(self.textFieldView)
            self.view.addSubview(bottomSeparator)
            self.view.addSubview(self.copyButton)
            self.view.addSubview(self.inputSeedValidImage)
            
            let offset: CGFloat = 20.0
            let bordersInset: CGFloat = 20.0
            let topInset: CGFloat = 14.0
            let fieldHeight: CGFloat = 40.0
            let iconSize: CGFloat = 16.0
            let separatorHeight: CGFloat = 1.0
            let buttonHeight: CGFloat = 44.0
            
            self.messageLabel.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(bordersInset)
                make.top.equalToSuperview().inset(topInset)
            }
            
            self.copyButton.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(bordersInset)
                make.height.equalTo(buttonHeight)
                make.top.equalTo(self.messageLabel.snp.bottom).offset(offset)
            }
            
            self.validateTitleLabel.snp.makeConstraints { (make) in
                make.leading.trailing.equalTo(self.messageLabel)
                make.top.equalTo(self.copyButton.snp.bottom).offset(offset)
            }
            
            topSeparator.snp.makeConstraints { (make) in
                make.leading.trailing.equalTo(self.messageLabel)
                make.top.equalTo(self.validateTitleLabel.snp.bottom).offset(offset)
                make.height.equalTo(separatorHeight)
            }
            
            self.textFieldView.snp.makeConstraints { (make) in
                make.leading.equalTo(self.validateTitleLabel)
                make.top.equalTo(topSeparator.snp.bottom).offset(2.0)
                make.height.equalTo(fieldHeight)
            }
            
            bottomSeparator.snp.makeConstraints { (make) in
                make.leading.trailing.equalTo(topSeparator)
                make.top.equalTo(self.textFieldView.snp.bottom).offset(2.0)
                make.height.equalTo(separatorHeight)
            }
            
            self.inputSeedValidImage.snp.makeConstraints { (make) in
                make.leading.equalTo(self.textFieldView.snp.trailing).offset(offset)
                make.trailing.equalToSuperview().inset(bordersInset)
                make.centerY.equalTo(self.textFieldView)
                make.size.equalTo(iconSize)
            }
        }
        
        private func setupSeparator(_ separator: UIView) {
            separator.backgroundColor = Theme.Colors.separatorOnContentBackgroundColor
            separator.isUserInteractionEnabled = false
        }
        
        private func updateInputSeedValid(_ valid: Model.InputSeedValidation) {
            let imageColor: UIColor
            switch valid {
                
            case .empty:
                imageColor = Theme.Colors.neutralSeedValidationColor
                
            case .invalid:
                imageColor = Theme.Colors.negativeSeedValidationColor
                
            case .valid:
                imageColor = Theme.Colors.positiveSeedValidationColor
            }
            
            self.inputSeedValidImage.tintColor = imageColor
        }
        
        private func showLastChanceAlert(onUnderstood: @escaping () -> Void) {
            let message = Localized(.this_seed_is_the_only_way)
            let options: [String] = [ Localized(.i_understand) ]
            let onSelected: (Int) -> Void = { _ in
                onUnderstood()
            }
            self.routing?.onShowAlertDialog(message, options, onSelected)
        }
    }
}

extension RecoverySeed.ViewController: RecoverySeed.DisplayLogic {
    func displayViewDidLoad(viewModel: RecoverySeed.Event.ViewDidLoad.ViewModel) {
        self.messageLabel.attributedText = viewModel.text
        self.updateInputSeedValid(viewModel.inputSeedValid)
    }
    
    func displayValidationSeedEditing(viewModel: RecoverySeed.Event.ValidationSeedEditing.ViewModel) {
        self.updateInputSeedValid(viewModel.inputSeedValid)
    }
    
    func displayCopyAction(viewModel: RecoverySeed.Event.CopyAction.ViewModel) {
        self.routing?.onShowMessage(viewModel.message)
    }
    
    func displayShowWarning(viewModel: RecoverySeed.Event.ShowWarning.ViewModel) {
        self.showLastChanceAlert(onUnderstood: { [weak self] in
            let request = RecoverySeed.Event.SignUpAction.Request()
            self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                businessLogic.onSignUpAction(request: request)
            })
        })
    }
    
    func displaySignUpAction(viewModel: RecoverySeed.Event.SignUpAction.ViewModel) {
        switch viewModel {
            
        case .loading:
            self.routing?.showLoading()
            
        case .loaded:
            self.routing?.hideLoading()
            
        case .success(let account, let walletData):
            self.routing?.onSuccessfulRegister(account, walletData)
            
        case .error(let error):
            self.routing?.onRegisterFailure(error)
        }
    }
}
