import UIKit

public protocol SignUpSceneDisplayLogic: AnyObject {
    
    typealias Event = SignUpScene.Event
    
    func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel)
    func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel)
    func displayDidTapCreateAccountButtonSync(viewModel: Event.DidTapCreateAccountButtonSync.ViewModel)
}

extension SignUpScene {
    
    public typealias DisplayLogic = SignUpSceneDisplayLogic
    
    @objc(SignUpSceneViewController)
    public class ViewController: BaseViewController {
        
        public typealias Event = SignUpScene.Event
        public typealias Model = SignUpScene.Model
        
        // MARK: -
        
        deinit {
            self.onDeinit?(self)
        }
        
        // MARK: - Private properties

        private let scrollView: UIScrollView = .init()
        private let scrollViewContentView: UIView = .init()
        private let textFieldsContainer: TextFieldsContainer = .init()
        private let networkTextField: TextField = .init()
        private let emailTextField: TextField = .init()
        private let passwordTextField: TextField = .init()
        private let passwordConfirmationTextField: TextField = .init()
        private let createAccountButton: ActionButton = .init()

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
                emailTextField,
                passwordTextField,
                passwordConfirmationTextField
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

private extension SignUpScene.ViewController {
    
    func setup() {
        setupView()
        setupScrollView()
        setupScrollViewContentView()
        setupTextFieldsContainer()
        setupNetworkTextField()
        setupEmailTextField()
        setupPasswordTextField()
        setupPasswordConfirmationTextField()
        setupCreateAccountButton()
        setupLayout()
    }
    
    func setupView() {
        view.backgroundColor = Theme.Colors.mainBackgroundColor
        navigationItem.title = Localized(.sign_up_title)
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
    
    func setupEmailTextField() {
        emailTextField.title = Localized(.sign_up_email_title)
        emailTextField.placeholder = "example@mail.com"
        emailTextField.capitalizationType = .none
        emailTextField.keyboardType = .emailAddress
        emailTextField.onTextChanged = { [weak self] (text) in
            let request: Event.DidEnterEmailSync.Request = .init(value: text)
            self?.interactorDispatch?.sendSyncRequest { (businessLogic) in
                businessLogic.onDidEnterEmailSync(request: request)
            }
        }
        
        emailTextField.onReturnAction = { [weak self] in
            guard let textField = self?.emailTextField
                else { return }
            self?.returnAction(for: textField)
        }
        
        let toolbar: UIToolbar = SharedViewsBuilder.configureToolbar()
        toolbar.items = [
            .init(
                title: Localized(.next),
                style: .done,
                target: self,
                action: #selector(emailTextFieldNextAction)
            )
        ]
        toolbar.sizeToFit()
        emailTextField.accessoryView = toolbar
    }
    
    @objc func emailTextFieldNextAction() {
        returnAction(for: emailTextField)
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
            guard let textField = self?.passwordTextField
                else { return }
            self?.returnAction(for: textField)
        }
        
        let toolbar: UIToolbar = SharedViewsBuilder.configureToolbar()
        toolbar.items = [
            .init(
                title: Localized(.next),
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
    
    func setupPasswordConfirmationTextField() {
        passwordConfirmationTextField.title = Localized(.sign_up_password_confirmation_title)
        passwordConfirmationTextField.isSecureTextEntry = true
        passwordConfirmationTextField.onTextChanged = { [weak self] (text) in
            let request: Event.DidEnterPasswordConfirmationSync.Request = .init(value: text)
            self?.interactorDispatch?.sendSyncRequest { (businessLogic) in
                businessLogic.onDidEnterPasswordConfirmationSync(request: request)
            }
        }
        
        passwordConfirmationTextField.onReturnAction = { [weak self] in
            guard let textField = self?.passwordConfirmationTextField
                else { return }
            self?.returnAction(for: textField)
        }
        
        let toolbar: UIToolbar = SharedViewsBuilder.configureToolbar()
        toolbar.items = [
            .init(
                title: Localized(.done),
                style: .done,
                target: self,
                action: #selector(passwordConfirmationTextFieldNextAction)
            )
        ]
        toolbar.sizeToFit()
        passwordConfirmationTextField.accessoryView = toolbar
    }
    
    @objc func passwordConfirmationTextFieldNextAction() {
        returnAction(for: passwordConfirmationTextField)
    }
    
    func setupCreateAccountButton() {
        createAccountButton.title = Localized(.sign_up_create_account)
        createAccountButton.onTouchUpInside = { [weak self] in
            self?.didTapCreateAccountButton()
        }
    }
    
    func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(scrollViewContentView)
        scrollViewContentView.addSubview(textFieldsContainer)
        scrollViewContentView.addSubview(createAccountButton)
        
        scrollView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeArea.top)
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
        
        createAccountButton.snp.makeConstraints { (make) in
            make.top.equalTo(textFieldsContainer.snp.bottom).offset(80.0)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(24.0)
        }
    }
    
    func setup(
        with sceneViewModel: Model.SceneViewModel,
        animated: Bool
    ) {
        
        networkTextField.text = sceneViewModel.network
        emailTextField.text = sceneViewModel.email
        passwordTextField.text = sceneViewModel.password
        passwordConfirmationTextField.text = sceneViewModel.passwordConfirmation
        
        networkTextField.error = sceneViewModel.networkError
        emailTextField.error = sceneViewModel.emailError
        passwordTextField.error = sceneViewModel.passwordError
        passwordConfirmationTextField.error = sceneViewModel.passwordConfirmationError
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
    
    func returnAction(for textField: TextField) {
        guard let index = textFieldsOrder.firstIndex(of: textField)
            else {
                return
        }
        
        if index < textFieldsOrder.count - 1 {
            textFieldsOrder[index + 1].becomeFirstResponder()
        } else {
            textFieldsOrder[index].resignFirstResponder()
            didTapCreateAccountButton()
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
        scrollView.snp.remakeConstraints { (remake) in
            remake.top.leading.trailing.equalToSuperview()
            if attributes?.showingIn(view: self.view) == true {
                remake.bottom.equalToSuperview().inset(keyboardHeightInView)
            } else {
                remake.bottom.equalToSuperview()
            }
        }
    }
    
    func didTapCreateAccountButton() {
        let request: Event.DidTapCreateAccountButtonSync.Request = .init()
        interactorDispatch?.sendSyncRequest { (businessLogic) in
            businessLogic.onDidTapCreateAccountButtonSync(request: request)
        }
    }
}

// MARK: - DisplayLogic

extension SignUpScene.ViewController: SignUpScene.DisplayLogic {
    
    public func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
    
    public func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
    
    public func displayDidTapCreateAccountButtonSync(viewModel: Event.DidTapCreateAccountButtonSync.ViewModel) {
        routing?.onCreateAccount(viewModel.email, viewModel.password)
    }
}
