import UIKit

public protocol SendAmountSceneDisplayLogic: AnyObject {
    
    typealias Event = SendAmountScene.Event
    
    func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel)
    func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel)
    func displayDidTapContinueSync(viewModel: Event.DidTapContinueSync.ViewModel)
}

extension SendAmountScene {
    
    public typealias DisplayLogic = SendAmountSceneDisplayLogic
    
    @objc(SendAmountSceneViewController)
    public class ViewController: BaseViewController {
        
        public typealias Event = SendAmountScene.Event
        public typealias Model = SendAmountScene.Model
        
        // MARK: -
        
        deinit {
            self.onDeinit?(self)
        }
        
        // MARK: - Private properties
        
        private let scrollView: UIScrollView = .init()
        private let scrollViewContentView: UIView = .init()
        private let recipientAddressLabel: UILabel = .init()
        private let balanceLabel: UILabel = .init()
        private let textFieldsContainer: TextFieldsContainer = .init()
        private let amountTextField: AmountTextField = .init()
        private let descriptionTextField: TextField = .init()
        private let feesStackView: FeesStackView = .init()
        private let continueButton: ActionButton = .init()
        
        private var textFieldsOrder: [UIView] = []

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
                amountTextField,
                descriptionTextField
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

private extension SendAmountScene.ViewController {
    
    func setup() {
        setupView()
        setupScrollView()
        setupScrollViewContentView()
        setupRecipientAddressLabel()
        setupBalanceLabel()
        setupTextFieldsContainer()
        setupAmountTextField()
        setupDescriptionTextField()
        setupContinueButton()
        setupLayout()
    }
    
    func setupView() {
        view.backgroundColor = Theme.Colors.mainBackgroundColor
    }
    
    func setupScrollView() {
        scrollView.backgroundColor = Theme.Colors.mainBackgroundColor
        scrollView.alwaysBounceVertical = false
        scrollView.keyboardDismissMode = .onDrag
    }
    
    func setupScrollViewContentView() {
        scrollViewContentView.backgroundColor = Theme.Colors.mainBackgroundColor
    }
    
    func setupRecipientAddressLabel() {
        recipientAddressLabel.font = Theme.Fonts.regularFont.withSize(16.0)
        recipientAddressLabel.textColor = Theme.Colors.dark
        recipientAddressLabel.numberOfLines = 1
        recipientAddressLabel.textAlignment = .left
        recipientAddressLabel.backgroundColor = Theme.Colors.mainBackgroundColor
    }
    
    func setupBalanceLabel() {
        balanceLabel.font = Theme.Fonts.regularFont.withSize(14.0)
        balanceLabel.textColor = Theme.Colors.dark
        balanceLabel.numberOfLines = 1
        balanceLabel.textAlignment = .left
        balanceLabel.backgroundColor = Theme.Colors.mainBackgroundColor
    }
    
    func setupTextFieldsContainer() {
        textFieldsContainer.textFieldsList = textFieldsOrder
    }
    
    func setupAmountTextField() {
        amountTextField.title = "Amount"
        amountTextField.keyboardType = .decimalPad
        amountTextField.onTextChanged = { [weak self] (textField) in
            let request: Event.DidEnterAmountSync.Request = .init(value: textField.amount)
            self?.interactorDispatch?.sendSyncRequest { (businessLogic) in
                businessLogic.onDidEnterAmountSync(request: request)
            }
        }
        
        amountTextField.onReturnAction = { [weak self] in
            guard let view = self?.amountTextField
            else {
                return
            }
            self?.returnAction(for: view)
        }
        
        let toolbar: UIToolbar = SharedViewsBuilder.configureToolbar()
        toolbar.items = [
            .init(
                title: Localized(.next),
                style: .done,
                target: self,
                action: #selector(amountTextFieldNextAction)
            )
        ]
        toolbar.sizeToFit()
        amountTextField.accessoryView = toolbar
    }
    
    @objc func amountTextFieldNextAction() {
        returnAction(for: amountTextField)
    }
    
    func setupDescriptionTextField() {
        descriptionTextField.title = "Description"
        descriptionTextField.placeholder = "(Optional)"
        descriptionTextField.onTextChanged = { [weak self] (text) in
            let request: Event.DidEnterDescriptionSync.Request = .init(value: text)
            self?.interactorDispatch?.sendSyncRequest { (businessLogic) in
                businessLogic.onDidEnterDescriptionSync(request: request)
            }
        }
        
        descriptionTextField.onReturnAction = { [weak self] in
            guard let view = self?.descriptionTextField
            else {
                return
            }
            self?.returnAction(for: view)
        }
        
        let toolbar: UIToolbar = SharedViewsBuilder.configureToolbar()
        toolbar.items = [
            .init(
                title: Localized(.done),
                style: .done,
                target: self,
                action: #selector(descriptionTextFieldNextAction)
            )
        ]
        toolbar.sizeToFit()
        descriptionTextField.accessoryView = toolbar
    }
    
    @objc func descriptionTextFieldNextAction() {
        returnAction(for: descriptionTextField)
    }
    
    func setupContinueButton() {
        continueButton.title = "Go to confirmation"
        continueButton.onTouchUpInside = { [weak self] in
            self?.didTapContinueButton()
        }
    }
    
    func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(scrollViewContentView)
        scrollViewContentView.addSubview(recipientAddressLabel)
        scrollViewContentView.addSubview(balanceLabel)
        scrollViewContentView.addSubview(textFieldsContainer)
        scrollViewContentView.addSubview(feesStackView)
        scrollViewContentView.addSubview(continueButton)
        
        scrollView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeArea.top)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        scrollViewContentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }
        
        recipientAddressLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(16.0)
            make.leading.trailing.equalToSuperview().inset(16.0)
        }
        
        balanceLabel.snp.makeConstraints { (make) in
            make.top.equalTo(recipientAddressLabel.snp.bottom).offset(48.0)
            make.leading.trailing.equalToSuperview().inset(16.0)
        }
        
        textFieldsContainer.snp.makeConstraints { (make) in
            make.top.equalTo(balanceLabel.snp.bottom).offset(12.0)
            make.leading.trailing.equalToSuperview()
        }
        
        feesStackView.snp.makeConstraints { (make) in
            make.top.equalTo(textFieldsContainer.snp.bottom).offset(32.0)
            make.leading.trailing.equalToSuperview()
        }
        
        continueButton.snp.makeConstraints { (make) in
            make.top.equalTo(feesStackView.snp.bottom).offset(24.0)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(32.0)
        }
        
        updateView(with: nil)
    }
    
    func setup(
        with sceneViewModel: Model.SceneViewModel,
        animated: Bool
    ) {
        
        navigationItem.title = "Send \(sceneViewModel.assetCode)"
        recipientAddressLabel.text = sceneViewModel.recipientAddress
        balanceLabel.text = sceneViewModel.availableBalance
        amountTextField.context = sceneViewModel.amountContext
        if let enteredAmount = sceneViewModel.enteredAmount {
            amountTextField.setAmount(enteredAmount)
        }
        amountTextField.error = sceneViewModel.enteredAmountError
        descriptionTextField.text = sceneViewModel.description
        
        var feesViews: [UIView] = []
        
        if let senderFeeModel = sceneViewModel.senderFeeModel {
            let view: FeeAmountView = .init()
            view.title = senderFeeModel.title
            view.value = senderFeeModel.value
            feesViews.append(view)
        }
        
        if let recipientFeeModel = sceneViewModel.recipientFeeModel {
            let view: FeeAmountView = .init()
            view.title = recipientFeeModel.title
            view.value = recipientFeeModel.value
            feesViews.append(view)
        }
        
        if let feeSwitcherModel = sceneViewModel.feeSwitcherModel {
            let view: FeeSwitcherView = .init()
            view.title = feeSwitcherModel.title
            view.value = feeSwitcherModel.switcherValue
            view.onSwitched = { [weak self] (value) in
                self?.interactorDispatch?.sendSyncRequest { (businessLogic) in
                    let request: Event.DidSwitchPayFeeForRecipientSync.Request = .init(value: value)
                    businessLogic.onDidSwitchPayFeeForRecipientSync(request: request)
                }
            }
            feesViews.append(view)
        }
        
        feesStackView.stackViewItems = feesViews
        feesStackView.isLoading = sceneViewModel.feeIsLoading
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
    
    func returnAction(for textField: UIView) {
        
        guard let index = textFieldsOrder.firstIndex(of: textField)
            else {
                return
        }
        
        if index < textFieldsOrder.count - 1 {
            textFieldsOrder[index + 1].becomeFirstResponder()
        } else {
            textFieldsOrder[index].resignFirstResponder()
            didTapContinueButton()
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
            }
        )
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
    
    func didTapContinueButton() {
        let request: Event.DidTapContinueSync.Request = .init()
        interactorDispatch?.sendSyncRequest { (businessLogic) in
            businessLogic.onDidTapContinueSync(request: request)
        }
    }
}

// MARK: - DisplayLogic

extension SendAmountScene.ViewController: SendAmountScene.DisplayLogic {
    
    public func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
    
    public func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
    
    public func displayDidTapContinueSync(viewModel: Event.DidTapContinueSync.ViewModel) {
        routing?.onContinue(
            viewModel.amount,
            viewModel.assetCode,
            viewModel.isPayingFeeForRecipient,
            viewModel.description
        )
    }
}
