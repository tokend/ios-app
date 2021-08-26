import UIKit

public protocol SendAssetSceneDisplayLogic: AnyObject {
    
    typealias Event = SendAssetScene.Event
    
    func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel)
    func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel)
    func displayDidTapContinueSync(viewModel: Event.DidTapContinueSync.ViewModel)
}

extension SendAssetScene {
    
    public typealias DisplayLogic = SendAssetSceneDisplayLogic
    
    @objc(SendAssetSceneViewController)
    public class ViewController: BaseViewController {
        
        public typealias Event = SendAssetScene.Event
        public typealias Model = SendAssetScene.Model
        
        // MARK: -
        
        deinit {
            self.onDeinit?(self)
        }
        
        // MARK: - Private properties
        
        private let textFieldsContainer: TextFieldsContainer = .init()
        private let recipientTextField: TextField = .init()

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
                recipientTextField
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

private extension SendAssetScene.ViewController {
    
    func setup() {
        setupView()
        setupTextFieldsContainer()
        setupRecipientTextField()
        setupLayout()
    }
    
    func setupView() {
        view.backgroundColor = Theme.Colors.mainBackgroundColor
        navigationItem.title = Localized(.send_asset_title)
        
        navigationItem.setRightBarButton(
            .init(
                title: Localized(.send_asset_continue),
                style: .plain,
                target: self,
                action: #selector(didTapContinue)
            ),
            animated: true
        )
    }
    
    func setupTextFieldsContainer() {
        textFieldsContainer.textFieldsList = textFieldsOrder
    }
    
    func setupRecipientTextField() {
        recipientTextField.title = Localized(.send_asset_recipient_title)
        recipientTextField.placeholder = Localized(.send_asset_recipient_placeholder)
        recipientTextField.keyboardType = .emailAddress
        recipientTextField.capitalizationType = .none
        recipientTextField.onTextChanged = { [weak self] (text) in
            let request: Event.DidEnterRecipientSync.Request = .init(value: text)
            self?.interactorDispatch?.sendSyncRequest { (businessLogic) in
                businessLogic.onDidEnterRecipientSync(request: request)
            }
        }
        
        let scanRecipientButton: UIButton = .init()
        scanRecipientButton.setImage(Assets.scan_qr_code_icon.image, for: .normal)
        scanRecipientButton.addTarget(
            self,
            action: #selector(scanRecipientButtonTouchUpInside),
            for: .touchUpInside
        )
        recipientTextField.accessoryButton = scanRecipientButton
    }
    
    @objc func scanRecipientButtonTouchUpInside() {
        routing?.onScanRecipient()
    }
    
    func setupLayout() {
        view.addSubview(textFieldsContainer)
        
        textFieldsContainer.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeArea.top).inset(40.0)
            make.leading.trailing.equalToSuperview()
        }
    }
    
    @objc func didTapContinue() {
        let request: Event.DidTapContinueSync.Request = .init()
        interactorDispatch?.sendSyncRequest { (businessLogic) in
            businessLogic.onDidTapContinueSync(request: request)
        }
    }
    
    func setup(
        with sceneViewModel: Model.SceneViewModel,
        animated: Bool
    ) {
        
        recipientTextField.text = sceneViewModel.recipientAddress
        recipientTextField.error = sceneViewModel.recipientError
    }
    
    func addKeyboardObserver() {
        let observer: KeyboardObserver = .init(
            self,
            keyboardWillChange: { [weak self] (attributes) in
//                self?.updateView(with: attributes)
            }
        )
        KeyboardController.shared.add(observer: observer)
    }
    
    func removeKeyboardObserver() {
        KeyboardController.shared.remove(observer: .init(self))
    }
}

// MARK: - DisplayLogic

extension SendAssetScene.ViewController: SendAssetScene.DisplayLogic {
    
    public func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
    
    public func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
    
    public func displayDidTapContinueSync(viewModel: Event.DidTapContinueSync.ViewModel) {
        routing?.onContinue(viewModel.recipient)
    }
}
