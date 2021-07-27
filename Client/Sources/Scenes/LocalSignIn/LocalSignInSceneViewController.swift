import UIKit
import Nuke

public protocol LocalSignInSceneDisplayLogic: AnyObject {
    
    typealias Event = LocalSignInScene.Event
    
    func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel)
    func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel)
    func displayDidTapBiometricsSync(viewModel: Event.DidTapBiometricsSync.ViewModel)
    func displayDidTapLoginButtonSync(viewModel: Event.DidTapLoginButtonSync.ViewModel)
}

extension LocalSignInScene {
    
    public typealias DisplayLogic = LocalSignInSceneDisplayLogic
    
    @objc(LocalSignInSceneViewController)
    public class ViewController: BaseViewController {
        
        public typealias Event = LocalSignInScene.Event
        public typealias Model = LocalSignInScene.Model
        
        // MARK: -
        
        deinit {
            self.onDeinit?(self)
        }
        
        // MARK: - Private properties

        private let scrollView: UIScrollView = .init()
        private let scrollViewContentView: UIView = .init()
        private let avatarBackgroundView: UIView = .init()
        private let avatarLabel: UILabel = .init()
        private let avatarImageView: UIImageView = .init()
        private let textFieldsContainer: TextFieldsContainer = .init()
        private let emailTextField: TextField = .init()
        private let passwordTextField: TextField = .init()
        private let forgotPasswordButton: UIButton = .init()
        private let biometricsButton: UIButton = .init()
        private let signInButton: ActionButton = .init()
        private let signOutButton: ActionButton = .init()
        
        private var textFieldsOrder: [TextField] = []
        
        private var biometricsTypeImageSize: CGSize { .init(width: 18.0, height: 20.0) }

        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        private var onDeinit: DeinitCompletion = nil
        
        public func inject(
            interactorDispatch: InteractorDispatch?,
            routing: Routing?,
            onDeinit: DeinitCompletion = nil
            ) {
            
            self.interactorDispatch = interactorDispatch
            self.routing = routing
            self.onDeinit = onDeinit
        }
        
        // MARK: - Overridden
        
        public override func viewDidLoad() {
            super.viewDidLoad()
            
            textFieldsOrder = [
                emailTextField,
                passwordTextField
            ]
            
            setup()
            
            let request = Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { (businessLogic) in
                businessLogic.onViewDidLoad(request: request)
            }
            
            let requestSync = Event.ViewDidLoadSync.Request()
            self.interactorDispatch?.sendSyncRequest { (businessLogic) in
                businessLogic.onViewDidLoadSync(request: requestSync)
            }
        }
        
        public override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            
            removeKeyboardObserver()
        }
        
        public override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            
            addKeyboardObserver()
        }
    }
}

// MARK: - Private methods

private extension LocalSignInScene.ViewController {
    
    func setup() {
        setupView()
        setupScrollView()
        setupScrollViewContentView()
        setupAvatarBackgroundView()
        setupAvatarLabel()
        setupAvatarImageView()
        setupTextFieldsContainer()
        setupEmailTextField()
        setupPasswordTextField()
        setupForgotPasswordButton()
        setupBiometricsTypeButton()
        setupSignInButton()
        setupSignOutButton()
        setupLayout()
    }
    
    func setupView() {
        view.backgroundColor = Theme.Colors.mainBackgroundColor
        navigationItem.title = Localized(.sign_in_title)
    }
    
    func setupScrollView() {
        scrollView.backgroundColor = Theme.Colors.mainBackgroundColor
        scrollView.alwaysBounceVertical = false
        scrollView.keyboardDismissMode = .onDrag
    }
    
    func setupScrollViewContentView() {
        scrollViewContentView.backgroundColor = Theme.Colors.mainBackgroundColor
    }
    
    func setupAvatarBackgroundView() {
        avatarBackgroundView.layer.cornerRadius = 62.0
        avatarBackgroundView.clipsToBounds = true
        avatarBackgroundView.backgroundColor = Theme.Colors.mainSeparatorColor
    }
    
    func setupAvatarLabel() {
        avatarLabel.font = Theme.Fonts.semiboldFont.withSize(40.0)
        avatarLabel.textColor = Theme.Colors.white
        avatarLabel.textAlignment = .center
    }
    
    func setupAvatarImageView() {
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.backgroundColor = .clear
    }
    
    func setupTextFieldsContainer() {
        textFieldsContainer.textFieldsList = textFieldsOrder
    }
    
    func setupEmailTextField() {
        
        // TODO: - Add info button
        
        emailTextField.title = Localized(.sign_up_email_title)
        emailTextField.isUserInteractionEnabled = false
    }
    
    func setupPasswordTextField() {
        passwordTextField.title = Localized(.sign_up_password_title)
        passwordTextField.isSecureTextEntry = true
        passwordTextField.onTextChanged = { [weak self] (text) in
            let request: Event.DidEnterPasswordSync.Request = .init(value: text)
            self?.interactorDispatch?.sendSyncRequest { (businessLogic) in
                businessLogic.onDidEnterPasswordSync(request: request)
            }
        }
        
        passwordTextField.onReturnAction = { [weak self] in
            self?.initiateSignIn()
        }
        
        let toolbar: UIToolbar = SharedViewsBuilder.configureToolbar()
        toolbar.items = [
            .init(
                title: Localized(.done),
                style: .done,
                target: self,
                action: #selector(passwordTextFieldDoneAction)
            )
        ]
        toolbar.sizeToFit()
        passwordTextField.accessoryView = toolbar
    }
    
    @objc func passwordTextFieldDoneAction() {
        initiateSignIn()
    }
    
    func setupForgotPasswordButton() {
        forgotPasswordButton.setTitle(Localized(.sign_in_forgot_password), for: .normal)
        forgotPasswordButton.backgroundColor = Theme.Colors.mainBackgroundColor
        forgotPasswordButton.titleLabel?.font = Theme.Fonts.mediumFont.withSize(14.0)
        forgotPasswordButton.setTitleColor(.systemBlue, for: .normal)
        forgotPasswordButton.contentEdgeInsets = .init(top: 5.0, left: 6.0, bottom: 5.0, right: 5.0)
        
        forgotPasswordButton.addTarget(
            self,
            action: #selector(forgotPasswordButtonTouchUpInside),
            for: .touchUpInside
        )
    }
    
    @objc func forgotPasswordButtonTouchUpInside() {
        routing?.onForgotPassword()
    }
    
    func setupBiometricsTypeButton() {
        biometricsButton.titleLabel?.font = Theme.Fonts.regularFont.withSize(16)
        biometricsButton.setTitleColor(.systemBlue, for: .normal)
        
        biometricsButton.addTarget(
            self,
            action: #selector(biometricsButtonTouchUpInside),
            for: .touchUpInside
        )
    }
    
    @objc func biometricsButtonTouchUpInside() {
        let request: Event.DidTapBiometricsSync.Request = .init()
        interactorDispatch?.sendSyncRequest { (businessLogic) in
            businessLogic.onDidTapBiometricsSync(request: request)
        }
    }
    
    func setupSignInButton() {
        signInButton.title = Localized(.sign_in_button)
        signInButton.onTouchUpInside = { [weak self] in
            self?.initiateSignIn()
        }
    }
    
    func setupSignOutButton() {
        signOutButton.title = Localized(.sign_out_button)
        signOutButton.onTouchUpInside = { [weak self] in
            self?.routing?.onSignOut()
        }
    }
    
    func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(scrollViewContentView)
        scrollViewContentView.addSubview(avatarBackgroundView)
        avatarBackgroundView.addSubview(avatarLabel)
        avatarBackgroundView.addSubview(avatarImageView)
        scrollViewContentView.addSubview(textFieldsContainer)
        scrollViewContentView.addSubview(forgotPasswordButton)
        scrollViewContentView.addSubview(biometricsButton)
        scrollViewContentView.addSubview(signInButton)
        scrollViewContentView.addSubview(signOutButton)
        
        scrollView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeArea.top)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        scrollViewContentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }
        
        avatarBackgroundView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(40.0)
            make.size.equalTo(CGSize(width: 124.0, height: 124.0))
            make.centerX.equalToSuperview()
        }
        
        avatarLabel.setContentHuggingPriority(.required, for: .horizontal)
        avatarLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        avatarLabel.setContentHuggingPriority(.required, for: .vertical)
        avatarLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        avatarLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        
        avatarImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        textFieldsContainer.snp.makeConstraints { (make) in
            make.top.equalTo(avatarImageView.snp.bottom).offset(40.0)
            make.leading.trailing.equalToSuperview()
        }
        
        forgotPasswordButton.snp.makeConstraints { (make) in
            make.top.equalTo(textFieldsContainer.snp.bottom).offset(7.0)
            make.leading.equalToSuperview().inset(10.0)
            make.height.equalTo(24.0)
        }
        
        biometricsButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(forgotPasswordButton.snp.bottom).offset(32.0)
        }
        
        signInButton.snp.makeConstraints { (make) in
            make.top.equalTo(biometricsButton.snp.bottom).offset(32.0)
            make.leading.trailing.equalToSuperview()
        }
        
        signOutButton.snp.makeConstraints { (make) in
            make.top.equalTo(signInButton.snp.bottom).offset(24.0)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(24.0)
        }
        
        updateView(with: nil)
    }
    
    func setup(
        with sceneViewModel: Model.SceneViewModel,
        animated: Bool
    ) {
        
        avatarLabel.text = sceneViewModel.avatarTitle
        emailTextField.text = sceneViewModel.login
        passwordTextField.text = sceneViewModel.password
        passwordTextField.error = sceneViewModel.passwordError
        
        if let biometricsTitle = sceneViewModel.biometricsTitle,
           let biometricsImage = sceneViewModel.biometricsImage {
            
            biometricsButton.setImage(
                biometricsImage,
                for: .normal
            )
            biometricsButton.setTitle(
                biometricsTitle,
                for: .normal
            )
            
            updateButtonContentInsets(with: biometricsTitle)
        } else {
            biometricsButton.isHidden = true
        }
        
        if avatarImageView.image == nil,
           let stringUrl = sceneViewModel.avatarUrl,
           let url = URL(string: stringUrl) {
            Nuke.loadImage(with: url, into: avatarImageView)
        }
    }
    
    func addKeyboardObserver() {
        let observer: KeyboardObserver = .init(
            self,
            keyboardWillChange: { [weak self] (attributes) in
                self?.updateView(with: attributes)
            }
        )
        KeyboardController.shared.add(observer: observer)
    }
    
    func removeKeyboardObserver() {
        KeyboardController.shared.remove(observer: .init(self))
    }
    
    func updateView(
        with attributes: KeyboardAttributes? = KeyboardController.shared.attributes
    ) {
        
        guard let attributes = attributes
        else {
            relayoutView(with: nil)
            return
        }
        
        UIView.animate(
            withKeyboardAttributes: attributes,
            animations: {
                self.relayoutView(with: attributes)
                if self.view.isVisible {
                    self.view.layoutIfNeeded()
                }
        })
    }
    
    func relayoutView(
        with attributes: KeyboardAttributes?
    ) {
        
        let keyboardHeightInView: CGFloat = attributes?.heightIn(view: self.view) ?? 0.0
        scrollView.snp.remakeConstraints({ (make) in
            make.top.leading.trailing.equalToSuperview()
            if attributes?.showingIn(view: self.view) == true {
                make.bottom.equalToSuperview().inset(keyboardHeightInView)
            } else {
                make.bottom.equalToSuperview()
            }
        })
        scrollToTextField(with: attributes)
    }
    
    func scrollToTextField(
        with attributes: KeyboardAttributes?
    ) {
        
        guard let attributes = attributes
            else {
                return
        }
        
        UIView.animate(
            withKeyboardAttributes: attributes,
            animations: {
                
                self.textFieldsOrder.forEach { (textField) in
                    if textField.isFirstResponder {
                        self.scrollView.scrollRectToVisible(
                            textField.frame,
                            animated: false
                        )
                    }
                }
        })
    }
    
    func initiateSignIn() {
        let request: Event.DidTapLoginButtonSync.Request = .init()
        interactorDispatch?.sendSyncRequest { (businessLogic) in
            businessLogic.onDidTapLoginButtonSync(request: request)
        }
    }
    
    func updateButtonContentInsets(with title: String) {
        
        let titleWidth = title.size(with: Theme.Fonts.regularFont.withSize(16.0)).width

        biometricsButton.imageEdgeInsets = UIEdgeInsets(
            top: 0,
            left: titleWidth + biometricsTypeImageSize.width + 15,
            bottom: 0,
            right: -(titleWidth + biometricsTypeImageSize.width + 15)
        )
        
        biometricsButton.contentEdgeInsets = UIEdgeInsets(
            top: 0,
            left: -biometricsTypeImageSize.width,
            bottom: 0,
            right: biometricsTypeImageSize.width + 15
        )
    }
}

// MARK: - DisplayLogic

extension LocalSignInScene.ViewController: LocalSignInScene.DisplayLogic {
    
    public func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
    
    public func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
    
    public func displayDidTapBiometricsSync(viewModel: Event.DidTapBiometricsSync.ViewModel) {
        routing?.onBiometrics()
    }
    
    public func displayDidTapLoginButtonSync(viewModel: Event.DidTapLoginButtonSync.ViewModel) {
        routing?.onSignIn(viewModel.password)
    }
}
