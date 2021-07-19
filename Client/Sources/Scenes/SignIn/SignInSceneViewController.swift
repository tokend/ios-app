import UIKit

public protocol SignInSceneDisplayLogic: class {
    
    typealias Event = SignInScene.Event
    
    func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel)
    func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel)
    func displayDidTapLoginButtonSync(viewModel: Event.DidTapLoginButtonSync.ViewModel)
}

extension SignInScene {
    
    public typealias DisplayLogic = SignInSceneDisplayLogic
    
    @objc(SignInSceneViewController)
    public class ViewController: BaseViewController {
        
        public typealias Event = SignInScene.Event
        public typealias Model = SignInScene.Model
        
        // MARK: -
        
        deinit {
            self.onDeinit?(self)
        }
        
        // MARK: - Private properties
        
        private let scrollView: UIScrollView = .init()
        private let scrollViewContentView: UIView = .init()
        private let textFieldsContainer: TextFieldsContainer = .init()
        private let networkTextField: TextField = .init()
        private let loginTextField: TextField = .init()
        private let passwordTextField: TextField = .init()
        private let forgotPasswordButton: UIButton = .init()
        private let signInButton: ActionButton = .init()
        private let signUpButton: ActionButton = .init()
        
        private var textFieldsOrder: [TextField] = []
        
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
                networkTextField,
                loginTextField,
                passwordTextField
            ]
            
            setup()
            
            let request = Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
            
            let requestSync = Event.ViewDidLoadSync.Request()
            self.interactorDispatch?.sendSyncRequest { businessLogic in
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

private extension SignInScene.ViewController {
    
    func setup() {
        setupView()
        setupScrollView()
        setupScrollViewContentView()
        setupTextFieldsContainer()
        setupNetworkTextField()
        setupLoginTextField()
        setupPasswordTextField()
        setupForgotPasswordButton()
        setupSignInButton()
        setupSignUpButton()
        setupLayout()
    }
    
    func setupView() {
        view.backgroundColor = Theme.Colors.mainBackgroundColor
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.navigationBar.prefersLargeTitles = true
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
    
    func setupTextFieldsContainer() {
        textFieldsContainer.textFieldsList = textFieldsOrder
    }
    
    func setupNetworkTextField() {
        networkTextField.title = Localized(.sign_in_network_title)
        networkTextField.placeholder = "network.example.com"
        networkTextField.setUserInteractionEnabled = false
        
        let selectNetworkButton: UIButton = .init()
        selectNetworkButton.setImage(Assets.scan_qr_code_icon.image, for: .normal)
        selectNetworkButton.addTarget(
            self,
            action: #selector(selectNetworkButtonTouchUpInside),
            for: .touchUpInside
        )
        networkTextField.accessoryButton = selectNetworkButton
    }
    
    @objc func selectNetworkButtonTouchUpInside() {
        routing?.onSelectNetwork()
    }
    
    func setupLoginTextField() {
        loginTextField.title = Localized(.sign_in_login_title)
        loginTextField.placeholder = "example@mail.com"
        loginTextField.capitalizationType = .none
        loginTextField.keyboardType = .emailAddress
        loginTextField.onTextChanged = { [weak self] (text) in
            let request: Event.DidEnterLoginSync.Request = .init(value: text)
            self?.interactorDispatch?.sendSyncRequest { (businessLogic) in
                businessLogic.onDidEnterLoginSync(request: request)
            }
        }
        
        loginTextField.onReturnAction = { [weak self] in
            guard let textField = self?.loginTextField
                else { return }
            self?.returnAction(for: textField)
        }
        
        let toolbar: UIToolbar = SharedViewsBuilder.configureToolbar()
        toolbar.items = [
            .init(
                title: Localized(.next),
                style: .done,
                target: self,
                action: #selector(loginTextFieldNextAction)
            )
        ]
        toolbar.sizeToFit()
        loginTextField.accessoryView = toolbar
    }
    
    @objc func loginTextFieldNextAction() {
        returnAction(for: loginTextField)
    }
    
    func setupPasswordTextField() {
        passwordTextField.title = Localized(.sign_in_password_title)
        passwordTextField.isSecureTextEntry = true
        passwordTextField.onTextChanged = { [weak self] (text) in
            let request: Event.DidEnterPasswordSync.Request = .init(value: text)
            self?.interactorDispatch?.sendSyncRequest { (businessLogic) in
                businessLogic.onDidEnterPasswordSync(request: request)
            }
        }
        
        passwordTextField.onReturnAction = { [weak self] in
            guard let textField = self?.passwordTextField
                else { return }
            self?.returnAction(for: textField)
        }
        
        let toolbar: UIToolbar = SharedViewsBuilder.configureToolbar()
        toolbar.items = [
            .init(
                title: Localized(.done),
                style: .done,
                target: self,
                action: #selector(passwordTextFieldNextAction)
            )
        ]
        toolbar.sizeToFit()
        passwordTextField.accessoryView = toolbar
    }
    
    @objc func passwordTextFieldNextAction() {
        returnAction(for: passwordTextField)
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
    
    func setupSignInButton() {
        signInButton.title = Localized(.sign_in_button)
        signInButton.onTouchUpInside = { [weak self] in
            self?.didTapLoginButton()
        }
    }
    
    func setupSignUpButton() {
        signUpButton.title = Localized(.sign_up_title)
        signUpButton.onTouchUpInside = { [weak self] in
            self?.routing?.onSignUp()
        }
    }
    
    func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(scrollViewContentView)
        scrollViewContentView.addSubview(textFieldsContainer)
        scrollViewContentView.addSubview(forgotPasswordButton)
        scrollViewContentView.addSubview(signInButton)
        scrollViewContentView.addSubview(signUpButton)
        
        scrollView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(24.0)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        scrollViewContentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }
        
        textFieldsContainer.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(40.0)
            make.leading.trailing.equalToSuperview()
        }
        
        forgotPasswordButton.snp.makeConstraints { (make) in
            make.top.equalTo(textFieldsContainer.snp.bottom).offset(7.0)
            make.leading.equalToSuperview().inset(10.0)
            make.height.equalTo(24.0)
        }
        
        signInButton.snp.makeConstraints { (make) in
            make.top.equalTo(forgotPasswordButton.snp.bottom).offset(40.0)
            make.leading.trailing.equalToSuperview()
        }
        
        signUpButton.snp.makeConstraints { (make) in
            make.top.equalTo(signInButton.snp.bottom).offset(12.0)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(24.0)
        }
        
        updateView(with: nil)
    }
    
    func setup(
        with sceneViewModel: Model.SceneViewModel,
        animated: Bool
    ) {
        networkTextField.text = sceneViewModel.network
        loginTextField.text = sceneViewModel.login
        passwordTextField.text = sceneViewModel.password
        
        networkTextField.error = sceneViewModel.networkError
        loginTextField.error = sceneViewModel.loginError
        passwordTextField.error = sceneViewModel.passwordError
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
        updateView(with: nil)
    }
    
    func returnAction(for textField: TextField) {
        guard let index = textFieldsOrder.firstIndex(of: textField)
            else {
                return
        }
        
        if index < textFieldsOrder.count - 1 {
            textFieldsOrder[index + 1].becomeFirstResponder()
        } else {
            textFieldsOrder[index].resignFirstResponder()
            didTapLoginButton()
        }
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
    
    func didTapLoginButton() {
        let request: Event.DidTapLoginButtonSync.Request = .init()
        interactorDispatch?.sendSyncRequest { (businessLogic) in
            businessLogic.onDidTapLoginButtonSync(request: request)
        }
    }
}

// MARK: - DisplayLogic

extension SignInScene.ViewController: SignInScene.DisplayLogic {
    
    public func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
    
    public func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
    
    public func displayDidTapLoginButtonSync(viewModel: Event.DidTapLoginButtonSync.ViewModel) {
        routing?.onSignIn(viewModel.login, viewModel.password)
    }
}
