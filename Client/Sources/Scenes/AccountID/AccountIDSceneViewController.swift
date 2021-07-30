import UIKit

public protocol AccountIDSceneDisplayLogic: AnyObject {
    
    typealias Event = AccountIDScene.Event
    
    func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel)
    func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel)
    func displayDidTapShareSync(viewModel: Event.DidTapShareSync.ViewModel)
}

extension AccountIDScene {
    
    public typealias DisplayLogic = AccountIDSceneDisplayLogic
    
    @objc(AccountIDSceneViewController)
    public class ViewController: BaseViewController {
        
        public typealias Event = AccountIDScene.Event
        public typealias Model = AccountIDScene.Model
        
        // MARK: -
        
        deinit {
            self.onDeinit?(self)
        }
        
        // MARK: - Private properties
        
        private let qrCodeImageView: QRCodeImageView = .init()
        private let qrCodeValueLabel: UILabel = .init()
        
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
            
            let request: Event.ViewDidLoad.Request = .init()
            self.interactorDispatch?.sendRequest { (businessLogic) in
                businessLogic.onViewDidLoad(request: request)
            }
            
            let requestSync: Event.ViewDidLoadSync.Request = .init()
            self.interactorDispatch?.sendSyncRequest { (businessLogic) in
                businessLogic.onViewDidLoadSync(request: requestSync)
            }
            
            setup()
        }
    }
}

// MARK: - Private methods

private extension AccountIDScene.ViewController {
    
    func setup() {
        setupView()
        setupNavigationBar()
        setupQrCodeImageView()
        setupQrCodeValueLabel()
        
        setupLayout()
    }
    
    func setupView() {
        view.backgroundColor = .groupTableViewBackground
    }
    
    func setupNavigationBar() {
        navigationItem.setRightBarButton(
            .init(
                barButtonSystemItem: .action,
                target: self,
                action: #selector(shareButtonAction)
            ),
            //                .init(
            //                    image: <#T##UIImage?#>,
            //                    style: <#T##UIBarButtonItem.Style#>,
            //                    target: <#T##Any?#>,
            //                    action: <#T##Selector?#>
            //                ),
            animated: false
        )
        
        navigationItem.setLeftBarButton(
            .init(
                image: Assets.arrow_back_icon.image,
                style: .plain,
                target: self,
                action: #selector(backButtonAction)
            ),
            animated: false
        )
        
        navigationItem.title = "Account ID"
    }
    
    @objc func shareButtonAction() {
        let request: Event.DidTapShareSync.Request = .init()
        self.interactorDispatch?.sendSyncRequest(requestBlock: { businessLogic in
            businessLogic.onDidTapShareSync(request: request)
        })
    }
    
    @objc func backButtonAction() {
        routing?.onBackAction()
    }
    
    func setupQrCodeImageView() {
        qrCodeImageView.backgroundColor = .clear
        qrCodeImageView.tintColor = .black
    }
    
    func setupQrCodeValueLabel() {
        qrCodeValueLabel.font = Theme.Fonts.regularFont.withSize(15.0)
        qrCodeValueLabel.textColor = .gray
        qrCodeValueLabel.numberOfLines = 0
        qrCodeValueLabel.textAlignment = .center
        qrCodeValueLabel.backgroundColor = .groupTableViewBackground
        qrCodeValueLabel.lineBreakMode = .byWordWrapping
    }
    
    func setupLayout() {
        
        view.addSubview(qrCodeImageView)
        view.addSubview(qrCodeValueLabel)
        
        qrCodeImageView.snp.makeConstraints { make in
            make.height.equalTo(qrCodeImageView.snp.width).priority(999.0)
            make.top.equalTo(view.safeArea.top).inset(32.0)
            make.leading.trailing.equalToSuperview().inset(32.0)
        }
        
        qrCodeValueLabel.setContentHuggingPriority(.required, for: .vertical)
        qrCodeValueLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        qrCodeValueLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(32.0)
            make.top.equalTo(qrCodeImageView.snp.bottom).offset(16.0)
            make.bottom.lessThanOrEqualToSuperview().inset(32.0)
        }
    }
    
    func setup(
        with sceneViewModel: Model.SceneViewModel,
        animated: Bool
    ) {
        
        qrCodeImageView.qrValue = sceneViewModel.qrCodeValue
        qrCodeValueLabel.text = sceneViewModel.qrCodeValue
    }
}

// MARK: - DisplayLogic

extension AccountIDScene.ViewController: AccountIDScene.DisplayLogic {
    
    public func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
    
    public func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
    
    public func displayDidTapShareSync(viewModel: Event.DidTapShareSync.ViewModel) {
        routing?.onShare(viewModel.value)
    }
}
