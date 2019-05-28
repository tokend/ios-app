import UIKit
import RxSwift

protocol DepositSceneDisplayLogic: class {
    typealias Event = DepositScene.Event
    
    func displayViewDidLoadSync(viewModel: Event.ViewDidLoadSync.ViewModel)
    func displayAssetsDidChange(viewModel: Event.AssetsDidChange.ViewModel)
    func displaySelectAsset(viewModel: Event.SelectAsset.ViewModel)
    func displayQRDidChange(viewModel: Event.QRDidChange.ViewModel)
    func displayAssetDidChange(viewModel: Event.AssetDidChange.ViewModel)
    func displayShare(viewModel: Event.Share.ViewModel)
    func displayError(viewModel: Event.Error.ViewModel)
    func displayLoading(viewModel: Event.Loading.ViewModel)
}

extension DepositScene {
    typealias DisplayLogic = DepositSceneDisplayLogic
    
    class ViewController: UIViewController {
        
        typealias Event = DepositScene.Event
        typealias Model = DepositScene.Model
        
        // MARK: - Private properties
        
        private let assetPicker: HorizontalPicker = HorizontalPicker()
        
        private let scrollContentView: UIScrollView = UIScrollView()
        
        private let addressContentView: UIView = UIView()
        private let addressQrCodeImageView: UIImageView = UIImageView()
        private let addressLabel: UILabel = UILabel()
        private let addressHintLabel: UILabel = UILabel()
        private let renewAddressButton: UIButton = UIButton(type: .custom)
        
        private let getAddressContentView: UIView = UIView()
        private let getAddressHintLabel: UILabel = UILabel()
        private let getAddressButton: UIButton = UIButton(type: .custom)
        
        private let emptyContentView: UIView = UIView()
        private let emptyHintLabel: UILabel = UILabel()
        
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
            self.setupAssetPicker()
            self.setupScrollContentView()
            self.setupAddressContentView()
            self.setupQrImageView()
            self.setupAddressLabel()
            self.setupAddressHintLabel()
            self.setupRenewAddressButton()
            
            self.setupGetAddressContentView()
            self.setupGetAddressHintLabel()
            self.setupGetAddressButton()
            
            self.setupEmptyContentView()
            self.setupEmptyHintLabel()
            
            self.setupLayout()
            
            let syncRequest = Event.ViewDidLoadSync.Request()
            self.interactorDispatch?.sendSyncRequest(requestBlock: { (businessLogic) in
                businessLogic.onViewDidLoadSync(request: syncRequest)
            })
            let request = Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            
            let request = Event.ViewDidLayoutSubviews.Request(qrCodeSize: self.addressQrCodeImageView.bounds.size)
            self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                businessLogic.onViewDidLayoutSubviews(request: request)
            })
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.containerBackgroundColor
        }
        
        private func setupAssetPicker() {
            self.assetPicker.backgroundColor = Theme.Colors.mainColor
            self.assetPicker.tintColor = Theme.Colors.darkAccentColor
        }
        
        private func setupScrollContentView() {
            self.scrollContentView.alwaysBounceVertical = false
            self.scrollContentView.alwaysBounceHorizontal = false
            self.scrollContentView.showsVerticalScrollIndicator = false
            self.scrollContentView.showsHorizontalScrollIndicator = false
        }
        
        private func setupAddressContentView() {
            self.addressContentView.backgroundColor = Theme.Colors.containerBackgroundColor
        }
        
        private func setupGetAddressContentView() {
            self.getAddressContentView.backgroundColor = Theme.Colors.containerBackgroundColor
        }
        
        private func setupEmptyContentView() {
            self.emptyContentView.backgroundColor = Theme.Colors.containerBackgroundColor
            
            let recognizer = UISwipeGestureRecognizer()
            recognizer.direction = .down
            recognizer.rx.event
                .asDriver()
                .drive ( onNext: { [weak self] (_) in
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        let request = Event.DidInitiateRefresh.Request()
                        businessLogic.onRefresh(request: request)
                    })
                })
                .disposed(by: self.disposeBag)
            self.emptyContentView.addGestureRecognizer(recognizer)
        }
        
        private func setupQrImageView() {
            self.addressQrCodeImageView.contentMode = .scaleAspectFit
        }
        
        private func setupAddressLabel() {
            self.addressLabel.textAlignment = .center
            self.addressLabel.adjustsFontSizeToFitWidth = true
            self.addressLabel.minimumScaleFactor = 0.01
            self.addressLabel.numberOfLines = 1
            self.addressLabel.textColor = Theme.Colors.textOnContainerBackgroundColor
            self.addressLabel.font = Theme.Fonts.plainTextFont
        }
        
        private func setupAddressHintLabel() {
            self.setupHintLabel(self.addressHintLabel)
        }
        
        private func setupRenewAddressButton() {
            self.setupButton(self.renewAddressButton)
            self.renewAddressButton.setTitle(Localized(.renew), for: .normal)
            self.renewAddressButton.addTarget(
                self,
                action: #selector(self.renewAddressButtonAction),
                for: .touchUpInside
            )
        }
        
        @objc private func renewAddressButtonAction() {
            self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                let request = Event.RenewAddress.Request()
                businessLogic.onRenewAddress(request: request)
            })
        }
        
        private func setupGetAddressHintLabel() {
            self.setupHintLabel(self.getAddressHintLabel)
        }
        
        private func setupGetAddressButton() {
            self.setupButton(self.getAddressButton)
            self.getAddressButton.setTitle(Localized(.get_address), for: .normal)
            self.getAddressButton.addTarget(
                self,
                action: #selector(self.getAddressButtonAction),
                for: .touchUpInside
            )
        }
        
        @objc private func getAddressButtonAction() {
            self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                let request = Event.GetAddress.Request()
                businessLogic.onGetAddress(request: request)
            })
        }
        
        private func setupEmptyHintLabel() {
            self.setupHintLabel(self.emptyHintLabel)
        }
        
        private func setupHintLabel(_ label: UILabel) {
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = false
            label.numberOfLines = 0
            label.textColor = Theme.Colors.sideTextOnContainerBackgroundColor
            label.font = Theme.Fonts.smallTextFont
        }
        
        private func setupButton(_ button: UIButton) {
            let buttonImage = UIImage.resizableImageWithColor(Theme.Colors.accentColor)
            button.setBackgroundImage(buttonImage, for: .normal)
            button.titleLabel?.font = Theme.Fonts.actionButtonFont
            button.setTitleColor(Theme.Colors.actionTitleButtonColor, for: .normal)
        }
        
        private func setupLayout() {
            self.view.addSubview(self.assetPicker)
            
            self.view.addSubview(self.scrollContentView)
            self.scrollContentView.addSubview(self.addressContentView)
            self.addressContentView.addSubview(self.addressQrCodeImageView)
            self.addressContentView.addSubview(self.addressLabel)
            self.addressContentView.addSubview(self.addressHintLabel)
            self.addressContentView.addSubview(self.renewAddressButton)
            
            self.view.addSubview(self.getAddressContentView)
            self.getAddressContentView.addSubview(self.getAddressHintLabel)
            self.getAddressContentView.addSubview(self.getAddressButton)
            
            self.view.addSubview(self.emptyContentView)
            self.emptyContentView.addSubview(self.emptyHintLabel)
            
            self.assetPicker.snp.makeConstraints { (make) in
                make.leading.trailing.top.equalToSuperview()
            }
            
            self.scrollContentView.snp.makeConstraints { (make) in
                make.top.equalTo(self.assetPicker.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }
            
            self.addressContentView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
                make.width.equalTo(self.scrollContentView.snp.width)
            }
            
            self.addressQrCodeImageView.snp.makeConstraints { (make) in
                make.width.equalTo(self.addressQrCodeImageView.snp.height)
                make.leading.equalToSuperview().inset(15)
                make.trailing.equalToSuperview().inset(15)
                make.top.equalToSuperview().inset(32)
            }
            
            self.addressLabel.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(15)
                make.top.equalTo(self.addressQrCodeImageView.snp.bottom).offset(24)
            }
            
            self.addressHintLabel.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(15)
                make.top.equalTo(self.addressLabel.snp.bottom).offset(12)
            }
            
            self.showRenewButton()
            
            self.getAddressContentView.snp.makeConstraints { (make) in
                make.top.equalTo(self.assetPicker.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }
            
            self.getAddressHintLabel.snp.makeConstraints { (make) in
                make.top.equalToSuperview().inset(32)
                make.leading.trailing.equalToSuperview().inset(15)
            }
            
            self.getAddressButton.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(15)
                make.top.equalTo(self.getAddressHintLabel.snp.bottom).offset(32)
                make.bottom.lessThanOrEqualToSuperview().inset(32)
                make.height.equalTo(44.0)
            }
            
            self.emptyContentView.snp.makeConstraints { (make) in
                make.top.equalTo(self.assetPicker.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }
            
            self.emptyHintLabel.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(15)
                make.top.equalToSuperview().inset(32)
                make.bottom.lessThanOrEqualToSuperview().inset(32)
            }
        }
        
        private func hideGetAddressButton() {
            self.getAddressButton.isHidden = true
            self.getAddressButton.snp.remakeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(15)
                make.top.equalTo(self.getAddressHintLabel.snp.bottom)
                make.bottom.lessThanOrEqualToSuperview().inset(32)
                make.height.equalTo(0)
            }
        }
        
        private func showGetAddressButton() {
            self.getAddressButton.isHidden = false
            self.getAddressButton.snp.remakeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(15)
                make.top.equalTo(self.getAddressHintLabel.snp.bottom).offset(32)
                make.bottom.lessThanOrEqualToSuperview().inset(32)
                make.height.equalTo(44.0)
            }
        }
        
        private func showGetAddressButtonLoading() {
            self.getAddressButton.showLoading(tintColor: Theme.Colors.textOnAccentColor)
            self.getAddressButton.isEnabled = false
        }
        
        private func hideGetAddressButtonLoading() {
            self.getAddressButton.hideLoading()
            self.getAddressButton.isEnabled = true
        }
        
        private func hideRenewButton() {
            self.renewAddressButton.isHidden = true
            self.renewAddressButton.snp.remakeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(15)
                make.top.equalTo(self.addressHintLabel.snp.bottom)
                make.bottom.equalToSuperview().inset(32)
                make.height.equalTo(0)
            }
        }
        
        private func showRenewButton() {
            self.renewAddressButton.isHidden = false
            self.renewAddressButton.snp.remakeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(15)
                make.top.equalTo(self.addressHintLabel.snp.bottom).offset(24)
                make.bottom.equalToSuperview().inset(32)
                make.height.equalTo(44.0)
            }
        }
        
        private func showRenewButtonLoading() {
            self.renewAddressButton.showLoading(tintColor: Theme.Colors.textOnAccentColor)
            self.renewAddressButton.isEnabled = false
        }
        
        private func hideRenewButtonLoading() {
            self.renewAddressButton.hideLoading()
            self.renewAddressButton.isEnabled = true
        }
        
        private func updateAssets(_ viewModel: Model.AssetsViewModel) {
            let items: [HorizontalPicker.Item] = {
                switch viewModel {
                case .assets(let assets):
                    return assets.map { [weak self] (asset) -> HorizontalPicker.Item in
                        return HorizontalPicker.Item(
                            title: asset.asset,
                            enabled: true,
                            onSelect: { [weak self] in
                                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                                    let request = Event.DidSelectAsset.Request(id: asset.id)
                                    businessLogic.onDidSelectAsset(request: request)
                                })
                            }
                        )
                    }
                case .empty(let title):
                    return [
                        HorizontalPicker.Item(
                            title: title,
                            enabled: false,
                            onSelect: { }
                        )
                    ]
                }
            }()
            self.assetPicker.items = items
        }
        
        private func enableSharing(_ enable: Bool) {
            var items: [UIBarButtonItem] = []
            
            if enable {
                let shareItem = UIBarButtonItem(
                    image: Assets.shareIcon.image,
                    style: .plain,
                    target: self,
                    action: #selector(self.shareAction)
                )
                items.append(shareItem)
            }
            
            self.navigationItem.rightBarButtonItems = items
        }
        
        @objc private func shareAction() {
            self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                let request = Event.Share.Request()
                businessLogic.onShare(request: request)
            })
        }
        
        private func updateSelectedIndexIfNeeded(_ index: Int?) {
            if let index = index {
                self.assetPicker.setSelectedItemAtIndex(index, animated: false)
            }
        }
    }
}

extension DepositScene.ViewController: DepositScene.DisplayLogic {
    func displayViewDidLoadSync(viewModel: Event.ViewDidLoadSync.ViewModel) {
        self.updateAssets(viewModel.assets)
        self.updateSelectedIndexIfNeeded(viewModel.selectedAssetIndex)
    }
    
    func displayAssetsDidChange(viewModel: Event.AssetsDidChange.ViewModel) {
        self.updateAssets(viewModel)
    }
    
    func displaySelectAsset(viewModel: Event.SelectAsset.ViewModel) {
        self.updateSelectedIndexIfNeeded(viewModel.index)
    }
    
    func displayQRDidChange(viewModel: Event.QRDidChange.ViewModel) {
        if self.addressQrCodeImageView.image == nil {
            self.addressQrCodeImageView.alpha = 0
        } else {
            self.addressQrCodeImageView.alpha = 1
        }
        self.addressQrCodeImageView.image = viewModel.qrCode
        if self.addressQrCodeImageView.alpha == 0 {
            UIView.animate(withDuration: 0.2) {
                self.addressQrCodeImageView.alpha = 1
            }
        }
    }
    
    func displayAssetDidChange(viewModel: Event.AssetDidChange.ViewModel) {
        switch viewModel {
            
        case .withAddress(let viewModel):
            self.scrollContentView.setContentOffset(.zero, animated: false)
            self.scrollContentView.isHidden = false
            
            self.emptyContentView.isHidden = true
            self.getAddressContentView.isHidden = true
            
            self.addressLabel.text = viewModel.address
            self.addressHintLabel.text = viewModel.hint
            
            switch viewModel.renewStatus {
            case .renewable:
                self.showRenewButton()
                self.hideRenewButtonLoading()
            case .notRenewable:
                self.hideRenewButton()
                self.hideRenewButtonLoading()
            case .renewing:
                self.showRenewButton()
                self.showRenewButtonLoading()
            }
            self.enableSharing(viewModel.canShare)
            
        case .withoutAddress(let viewModel):
            self.getAddressContentView.isHidden = false
            
            self.emptyContentView.isHidden = true
            self.scrollContentView.isHidden = true
            
            self.getAddressHintLabel.text = viewModel.hint
            switch viewModel.renewStatus {
            case .renewable:
                self.showGetAddressButton()
                self.hideGetAddressButtonLoading()
            case .notRenewable:
                self.hideGetAddressButton()
                self.hideGetAddressButtonLoading()
            case .renewing:
                self.showGetAddressButton()
                self.showGetAddressButtonLoading()
            }
            self.enableSharing(false)
            
        case .empty(let hint):
            self.emptyContentView.isHidden = false
            
            self.getAddressContentView.isHidden = true
            self.scrollContentView.isHidden = true
            
            self.emptyHintLabel.text = hint
            self.enableSharing(false)
        }
    }
    
    func displayShare(viewModel: Event.Share.ViewModel) {
        self.routing?.onShare(viewModel.items)
    }
    
    func displayError(viewModel: Event.Error.ViewModel) {
        self.routing?.onError(viewModel.message)
    }
    
    func displayLoading(viewModel: Event.Loading.ViewModel) {
        switch viewModel.status {
            
        case .loaded:
            self.emptyContentView.hideLoading()
            
        case .loading:
            self.emptyContentView.showLoading()
        }
    }
}
