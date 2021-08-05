import UIKit

public protocol ChangePasswordSceneDisplayLogic: AnyObject {
    
    typealias Event = ChangePasswordScene.Event
    
    func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel)
    func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel)
    func displayDidTapChangeButtonSync(viewModel: Event.DidTapChangeButtonSync.ViewModel)
}

extension ChangePasswordScene {
    
    public typealias DisplayLogic = ChangePasswordSceneDisplayLogic
    
    @objc(ChangePasswordSceneViewController)
    public class ViewController: BaseViewController {
        
        public typealias Event = ChangePasswordScene.Event
        public typealias Model = ChangePasswordScene.Model
        
        // MARK: -
        
        deinit {
            self.onDeinit?(self)
        }
        
        // MARK: - Private properties
        
        private let scrollView: UIScrollView = .init()
        private let scrollViewContentView: UIView = .init()
        private let textFieldsContainer: TextFieldsContainer = .init()
        private let currentPasswordTextField: TextField = .init()
        private let newPasswordTextField: TextField = .init()
        private let confirmPasswordTextField: TextField = .init()
        private let changeButton: ActionButton = .init()
        
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
                currentPasswordTextField,
                newPasswordTextField,
                confirmPasswordTextField
            ]
            
            setup()
            
            let request: Event.ViewDidLoad.Request = .init()
            self.interactorDispatch?.sendRequest { (businessLogic) in
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

private extension ChangePasswordScene.ViewController {
    
    func setup() {
        setupView()
        setupNavigationBar()
        setupScrollView()
        setupScrollViewContentView()
        setupTextFieldsContainer()
        setupCurrentPasswordTextField()
        setupNewPasswordTextField()
        setupConfirmPasswordTextField()
        setupChangeButton()
        setupLayout()
    }
    
    func setupView() {
        view.backgroundColor = Theme.Colors.mainBackgroundColor
    }
    
    func setupNavigationBar() {
        navigationItem.setLeftBarButton(
            .init(
                image: Assets.arrow_back_icon.image,
                style: .plain,
                target: self,
                action: #selector(backButtonAction)
            ),
            animated: false
        )
        
        navigationItem.title = Localized(.change_password_title)
    }
    
    @objc func backButtonAction() {
        routing?.onBackAction()
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
    
    func setupCurrentPasswordTextField() {
        currentPasswordTextField.title = Localized(.change_password_current_password_title)
        currentPasswordTextField.isSecureTextEntry = true
        currentPasswordTextField.capitalizationType = .none
        currentPasswordTextField.keyboardType = .default
        currentPasswordTextField.contentType = .password
        currentPasswordTextField.placeholder = Localized(.change_password_password_placeholder)
        currentPasswordTextField.onTextChanged = { [weak self] (text) in
            let request: Event.DidEnterCurrentPasswordSync.Request = .init(value: text)
            self?.interactorDispatch?.sendSyncRequest { (businessLogic) in
                businessLogic.onDidEnterCurrentPasswordSync(request: request)
            }
        }
        
        currentPasswordTextField.onReturnAction = { [weak self] in
            guard let textField = self?.currentPasswordTextField
                else { return }
            self?.returnAction(for: textField)
        }
        
        let toolbar: UIToolbar = SharedViewsBuilder.configureToolbar()
        toolbar.items = [
            .init(
                title: Localized(.next),
                style: .done,
                target: self,
                action: #selector(currentPasswordTextFieldNextAction)
            )
        ]
        toolbar.sizeToFit()
        currentPasswordTextField.accessoryView = toolbar
    }
    
    @objc func currentPasswordTextFieldNextAction() {
        returnAction(for: currentPasswordTextField)
    }
    
    func setupNewPasswordTextField() {
        newPasswordTextField.title = Localized(.change_password_new_password_title)
        newPasswordTextField.isSecureTextEntry = true
        newPasswordTextField.capitalizationType = .none
        newPasswordTextField.keyboardType = .default
        newPasswordTextField.placeholder = Localized(.change_password_password_placeholder)
        if #available(iOS 12.0, *) {
            newPasswordTextField.contentType = .newPassword
        }
        newPasswordTextField.onTextChanged = { [weak self] (text) in
            let request: Event.DidEnterNewPasswordSync.Request = .init(value: text)
            self?.interactorDispatch?.sendSyncRequest { (businessLogic) in
                businessLogic.onDidEnterNewPasswordSync(request: request)
            }
        }
        
        newPasswordTextField.onReturnAction = { [weak self] in
            guard let textField = self?.newPasswordTextField
                else { return }
            self?.returnAction(for: textField)
        }
        
        let toolbar: UIToolbar = SharedViewsBuilder.configureToolbar()
        toolbar.items = [
            .init(
                title: Localized(.next),
                style: .done,
                target: self,
                action: #selector(newPasswordTextFieldNextAction)
            )
        ]
        toolbar.sizeToFit()
        newPasswordTextField.accessoryView = toolbar
    }
    
    @objc func newPasswordTextFieldNextAction() {
        returnAction(for: newPasswordTextField)
    }
    
    func setupConfirmPasswordTextField() {
        confirmPasswordTextField.title = Localized(.change_password_confirm_new_password_title)
        confirmPasswordTextField.isSecureTextEntry = true
        confirmPasswordTextField.capitalizationType = .none
        confirmPasswordTextField.keyboardType = .default
        confirmPasswordTextField.placeholder = Localized(.change_password_password_placeholder)
        if #available(iOS 12.0, *) {
            confirmPasswordTextField.contentType = .newPassword
        }
        confirmPasswordTextField.onTextChanged = { [weak self] (text) in
            let request: Event.DidEnterConfirmPasswordSync.Request = .init(value: text)
            self?.interactorDispatch?.sendSyncRequest { (businessLogic) in
                businessLogic.onDidEnterConfirmPasswordSync(request: request)
            }
        }
        
        confirmPasswordTextField.onReturnAction = { [weak self] in
            guard let textField = self?.confirmPasswordTextField
                else { return }
            self?.returnAction(for: textField)
        }
        
        let toolbar: UIToolbar = SharedViewsBuilder.configureToolbar()
        toolbar.items = [
            .init(
                title: Localized(.done),
                style: .done,
                target: self,
                action: #selector(confirmPasswordTextFieldNextAction)
            )
        ]
        toolbar.sizeToFit()
        confirmPasswordTextField.accessoryView = toolbar
    }
    
    @objc func confirmPasswordTextFieldNextAction() {
        returnAction(for: confirmPasswordTextField)
    }
    
    func setupChangeButton() {
        changeButton.title = Localized(.change_password_button)
        changeButton.onTouchUpInside = { [weak self] in
            self?.didTapChangeButton()
        }
    }
    
    func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(scrollViewContentView)
        scrollViewContentView.addSubview(textFieldsContainer)
        scrollViewContentView.addSubview(changeButton)
        
        scrollView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
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
        
        changeButton.snp.makeConstraints { (make) in
            make.top.equalTo(textFieldsContainer.snp.bottom).offset(40.0)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(24.0)
        }
        
        updateView(with: nil)
    }
    
    func setup(
        with sceneViewModel: Model.SceneViewModel,
        animated: Bool
    ) {
        
        currentPasswordTextField.text = sceneViewModel.currentPassword
        newPasswordTextField.text = sceneViewModel.newPassword
        confirmPasswordTextField.text = sceneViewModel.confirmPassword
        
        currentPasswordTextField.error = sceneViewModel.currentPasswordError
        newPasswordTextField.error = sceneViewModel.newPasswordError
        confirmPasswordTextField.error = sceneViewModel.confirmPasswordError
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
            didTapChangeButton()
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
    
    func didTapChangeButton() {
        let request: Event.DidTapChangeButtonSync.Request = .init()
        interactorDispatch?.sendSyncRequest { (businessLogic) in
            businessLogic.onDidTapChangeButtonSync(request: request)
        }
    }
}

// MARK: - DisplayLogic

extension ChangePasswordScene.ViewController: ChangePasswordScene.DisplayLogic {
    
    public func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
    
    public func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
    
    public func displayDidTapChangeButtonSync(viewModel: Event.DidTapChangeButtonSync.ViewModel) {
        routing?.onChangePassword(viewModel.currentPassword, viewModel.newPassword)
    }
}
