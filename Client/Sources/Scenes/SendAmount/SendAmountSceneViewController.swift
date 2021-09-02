import UIKit

public protocol SendAmountSceneDisplayLogic: AnyObject {
    
    typealias Event = SendAmountScene.Event
    
    func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel)
    func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel)
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
        private let assetAmountView: AssetAmountView = .init()
        private let feeLabel: UILabel = .init()
        private let textFieldsContainer: TextFieldsContainer = .init()
        private let descriptionTextField: TextField = .init()
        private let continueButton: ActionButton = .init()
                
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
        setupAssetAmountView()
        setupFeeLabel()
        setupDescriptionTextField()
        setupContinueButton()
        setupLayout()
    }
    
    func setupView() {
        view.backgroundColor = Theme.Colors.mainBackgroundColor
        navigationItem.title = "Send"
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
        recipientAddressLabel.textAlignment = .center
        recipientAddressLabel.backgroundColor = Theme.Colors.mainBackgroundColor
    }
    
    func setupBalanceLabel() {
        balanceLabel.font = Theme.Fonts.regularFont.withSize(14.0)
        balanceLabel.textColor = Theme.Colors.dark
        balanceLabel.numberOfLines = 1
        balanceLabel.textAlignment = .center
        balanceLabel.backgroundColor = Theme.Colors.mainBackgroundColor
    }
    
    func setupAssetAmountView() {
        assetAmountView.assetPickerIcon = Assets.arrow_down_icon.image
        assetAmountView.onSelectedPicker = { [weak self] in
            self?.routing?.onSelectBalance(
                { [weak self] (balanceId) in
                    let request: Event.DidSelectBalanceSync.Request = .init()
                }
            )
        }
        
        assetAmountView.onReturnAction = { [weak self] in
            guard let view = self?.assetAmountView
            else {
                return
            }
            self?.returnAction(for: view)
        }
    }
    
    func setupFeeLabel() {
        feeLabel.font = Theme.Fonts.regularFont.withSize(14.0)
        feeLabel.textColor = Theme.Colors.dark
        feeLabel.numberOfLines = 1
        feeLabel.textAlignment = .center
        feeLabel.backgroundColor = Theme.Colors.mainBackgroundColor
    }
    
    func setupDescriptionTextField() {
        textFieldsContainer.textFieldsList = [descriptionTextField]
        
        descriptionTextField.title = "Description"
        descriptionTextField.placeholder = "Optional"
        descriptionTextField.onTextChanged = { [weak self] (text) in
            let request: Event.DidEnterDescriptionSync.Request = .init(value: text)
//            self?.interactorDispatch?.sendSyncRequest { (businessLogic) in
//                businessLogic.onDidEnterDescriptionSync(request: request)
//            }
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
        scrollViewContentView.addSubview(assetAmountView)
        scrollViewContentView.addSubview(feeLabel)
        scrollViewContentView.addSubview(textFieldsContainer)
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
            make.top.equalToSuperview().inset(32.0)
            make.leading.trailing.equalToSuperview()
        }
        
        balanceLabel.snp.makeConstraints { (make) in
            make.top.equalTo(recipientAddressLabel.snp.bottom).offset(80.0)
            make.centerX.equalToSuperview()
        }
        
        assetAmountView.snp.makeConstraints { (make) in
            make.top.equalTo(balanceLabel.snp.bottom).offset(24.0)
            make.leading.greaterThanOrEqualToSuperview().inset(24.0)
            make.trailing.lessThanOrEqualToSuperview().inset(24.0)
            make.centerX.equalToSuperview()
        }
        
        feeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(assetAmountView.snp.bottom).offset(16.0)
            make.centerX.equalToSuperview()
        }
        
        textFieldsContainer.snp.makeConstraints { (make) in
            make.top.equalTo(feeLabel.snp.bottom).offset(64.0)
            make.leading.trailing.equalToSuperview()
        }
        
        continueButton.snp.makeConstraints { (make) in
            make.top.equalTo(textFieldsContainer.snp.bottom).offset(24.0)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(32.0)
        }
        
        updateView(with: nil)
    }
    
    func setup(
        with sceneViewModel: Model.SceneViewModel,
        animated: Bool
    ) {
        recipientAddressLabel.text = sceneViewModel.recipientAddress
//        assetAmountView.text = sceneViewModel.amount
        assetAmountView.assetPickerTitle = sceneViewModel.assetCode
        feeLabel.text = sceneViewModel.fee
        descriptionTextField.text = sceneViewModel.description
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
    
    func returnAction(for view: UIView) {
        
        if view == assetAmountView {
            descriptionTextField.becomeFirstResponder()
        } else if view == descriptionTextField {
            view.resignFirstResponder()
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
                
                if self.assetAmountView.isFirstResponder {
                    self.scrollView.scrollRectToVisible(
                        self.assetAmountView.frame,
                        animated: false
                    )
                } else if self.descriptionTextField.isFirstResponder {
                    self.scrollView.scrollRectToVisible(
                        self.descriptionTextField.frame,
                        animated: false
                    )
                }
        })
    }
    
    func didTapContinueButton() {
        let request: Event.DidTapContinueSync.Request = .init()
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
}
