import UIKit
import RxSwift
import Nuke
import WebKit

extension SaleDetails {
    
    enum DescriptionCell {
        
        struct ViewModel: CellViewModel {
            
            let imageUrl: URL?
            let name: String
            let description: String
            
            let youtubeVideoUrl: URL?
            
            let investedAmountText: NSAttributedString
            let investedPercentage: Float
            let investedPercentageText: String
            let investorsText: NSAttributedString
            
            let timeText: NSAttributedString
            
            let identifier: CellIdentifier
            
            func setup(cell: DescriptionCell.View) {
                cell.imageURL = self.imageUrl
                cell.saleName = self.name
                cell.saleDescription = self.description
                
                cell.youtubeVideoURL = self.youtubeVideoUrl
                
                cell.investedAmountText = self.investedAmountText
                cell.investedPercentageText = self.investedPercentageText
                cell.investedPercent = self.investedPercentage
                cell.investorsAmountText = self.investorsText
                
                cell.timeText = self.timeText
                
                cell.identifier = self.identifier
            }
        }
        
        class View: UITableViewCell {
            
            // MARK: - Public property
            
            typealias DidSelectButton = (_ cellIdentifier: CellIdentifier) -> Void
            
            public var onDidSelectMoreInfoButton: DidSelectButton?
            
            public var imageURL: URL? {
                didSet {
                    if let imageURL = self.imageURL {
                        Nuke.loadImage(
                            with: imageURL,
                            into: self.assetImageView
                        )
                    } else {
                        self.assetImageView.image = nil
                    }
                }
            }
            
            public var youtubeVideoURL: URL? {
                didSet {
                    guard let url = self.youtubeVideoURL
                        else {
                            self.hideVideoWebViewIfNeeded()
                            return
                    }
                    self.showVideoWebViewIfNeeded()
                    let request = URLRequest(url: url)
                    self.videoWebView.load(request)
                }
            }
            
            public var saleName: String? {
                get { return self.nameLabel.text }
                set { self.nameLabel.text = newValue }
            }
            
            public var saleDescription: String? {
                get { return self.shortDescriptionLabel.text }
                set { self.shortDescriptionLabel.text = newValue }
            }
            
            public var investedAmountText: NSAttributedString? {
                get { return self.investedAmountLabel.attributedText }
                set { self.investedAmountLabel.attributedText = newValue }
            }
            
            public var investedPercent: Float {
                get { return self.progressView.progress }
                set { self.progressView.progress = newValue }
            }
            
            public var investedPercentageText: String? {
                get { return self.percentLabel.text }
                set { self.percentLabel.text = newValue }
            }
            
            public var investorsAmountText: NSAttributedString? {
                get { return self.investorsAmountLabel.attributedText }
                set { self.investorsAmountLabel.attributedText = newValue }
            }
            
            public var timeText: NSAttributedString? {
                get { return self.timeLabel.attributedText }
                set { self.timeLabel.attributedText = newValue }
            }
            
            public var identifier: CellIdentifier = .empty
            
            // MARK: - Private properties
            
            private let disposeBag = DisposeBag()
            
            private let iconSize: CGFloat = 45
            
            private let assetImageView: UIImageView = UIImageView()
            private let nameLabel: UILabel = UILabel()
            private let shortDescriptionLabel: UILabel = UILabel()
            private let investContentView: UIView = UIView()
            private let videoWebView: WKWebView = WKWebView()
            
            private var saleImageDisposable: Disposable?
            
            // Invested views
            
            private let investedAmountLabel: UILabel = UILabel()
            private let percentLabel: UILabel = UILabel()
            private let progressView: UIProgressView = UIProgressView()
            private let investorsAmountLabel: UILabel = UILabel()
            private let timeLabel: UILabel = UILabel()
            
            private let separatorView: UIView = UIView()
            private let moreInfoButton: UIButton = UIButton(type: .custom)
            
            private let sideInset: CGFloat = 20
            private let topInset: CGFloat = 15
            private let bottomInset: CGFloat = 15
            
            // MARK: -
            
            override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
                super.init(style: style, reuseIdentifier: reuseIdentifier)
                
                self.commonInit()
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            deinit {
                self.saleImageDisposable?.dispose()
            }
            
            // MARK: - Private
            
            private func commonInit() {
                self.setupView()
                self.setupAssetImageView()
                self.setupNameLabel()
                self.setupShortDescriptionLabel()
                self.setupInvestedAmountLabel()
                self.setupPercentLabel()
                self.setupProgressView()
                self.setupInvestorsAmountLabel()
                self.setupTimeLabel()
                self.setupVideoWebView()
                self.setupSeparator()
                self.setupMoreInfoButton()
                
                self.setupLayout()
            }
            
            private func setupView() {
                self.backgroundColor = Theme.Colors.contentBackgroundColor
                self.selectionStyle = .none
            }
            
            private func setupAssetImageView() {
                self.assetImageView.contentMode = .scaleAspectFit
                self.assetImageView.backgroundColor = UIColor.clear
            }
            
            private func setupNameLabel() {
                self.nameLabel.font = Theme.Fonts.largeTitleFont
                self.nameLabel.textColor = Theme.Colors.textOnContentBackgroundColor
                self.nameLabel.textAlignment = .left
                self.nameLabel.numberOfLines = 2
                self.nameLabel.lineBreakMode = .byWordWrapping
            }
            
            private func setupShortDescriptionLabel() {
                self.shortDescriptionLabel.font = Theme.Fonts.smallTextFont
                self.shortDescriptionLabel.textColor = Theme.Colors.textOnContentBackgroundColor
                self.shortDescriptionLabel.textAlignment = .left
                self.shortDescriptionLabel.numberOfLines = 0
                self.shortDescriptionLabel.lineBreakMode = .byWordWrapping
            }
            
            private func setupInvestedAmountLabel() {
                self.investedAmountLabel.font = Theme.Fonts.smallTextFont
                self.investedAmountLabel.textColor = Theme.Colors.accentColor
                self.investedAmountLabel.textAlignment = .left
            }
            
            private func setupPercentLabel() {
                self.percentLabel.font = Theme.Fonts.smallTextFont
                self.percentLabel.textColor = Theme.Colors.textOnContentBackgroundColor
                self.percentLabel.textAlignment = .right
            }
            
            private func setupProgressView() {
                self.progressView.tintColor = Theme.Colors.accentColor
            }
            
            private func setupInvestorsAmountLabel() {
                self.investorsAmountLabel.font = Theme.Fonts.smallTextFont
                self.investorsAmountLabel.textColor = Theme.Colors.accentColor
                self.investorsAmountLabel.textAlignment = .left
            }
            
            private func setupTimeLabel() {
                self.timeLabel.font = Theme.Fonts.smallTextFont
                self.timeLabel.textColor = Theme.Colors.accentColor
                self.timeLabel.textAlignment = .right
            }
            
            private func setupVideoWebView() {
                self.videoWebView.allowsLinkPreview = false
                self.videoWebView.allowsBackForwardNavigationGestures = false
                self.videoWebView.backgroundColor = UIColor.clear
                
                let configuration = self.videoWebView.configuration
                configuration.allowsAirPlayForMediaPlayback = false
                configuration.allowsInlineMediaPlayback = false
                configuration.allowsPictureInPictureMediaPlayback = false
                configuration.ignoresViewportScaleLimits = false
            }
            
            private func setupSeparator() {
                self.separatorView.backgroundColor = Theme.Colors.separatorOnContentBackgroundColor
                self.separatorView.isUserInteractionEnabled = false
            }
            
            private func setupMoreInfoButton() {
                self.moreInfoButton.setTitleColor(Theme.Colors.actionButtonColor, for: .normal)
                self.moreInfoButton.titleLabel?.font = Theme.Fonts.actionButtonFont
                self.moreInfoButton.setTitle(Localized(.more_info), for: .normal)
                self.moreInfoButton.contentEdgeInsets = UIEdgeInsets(
                    top: 0.0, left: self.sideInset, bottom: 0.0, right: 0.0
                )
                
                self.moreInfoButton
                    .rx
                    .controlEvent(.touchUpInside)
                    .asDriver()
                    .drive(onNext: { [weak self] in
                        self?.onDidSelectMoreInfoButton?(.details)
                    })
                    .disposed(by: self.disposeBag)
            }
            
            private func setupLayout() {
                self.contentView.addSubview(self.assetImageView)
                self.contentView.addSubview(self.nameLabel)
                self.contentView.addSubview(self.shortDescriptionLabel)
                self.contentView.addSubview(self.investContentView)
                self.contentView.addSubview(self.videoWebView)
                self.contentView.addSubview(self.separatorView)
                self.contentView.addSubview(self.moreInfoButton)
                
                self.assetImageView.snp.makeConstraints { (make) in
                    make.leading.equalToSuperview().inset(self.sideInset)
                    make.top.equalToSuperview().inset(self.topInset)
                    make.width.height.equalTo(self.iconSize)
                }
                
                self.nameLabel.snp.makeConstraints { (make) in
                    make.leading.equalTo(self.assetImageView.snp.trailing).offset(self.sideInset)
                    make.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.equalTo(self.assetImageView.snp.top)
                }
                
                self.shortDescriptionLabel.snp.makeConstraints { (make) in
                    make.top.greaterThanOrEqualTo(self.assetImageView.snp.bottom).offset(self.topInset)
                    make.top.greaterThanOrEqualTo(self.nameLabel.snp.bottom).offset(self.topInset)
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                }
                
                self.investContentView.snp.makeConstraints { (make) in
                    make.top.equalTo(self.shortDescriptionLabel.snp.bottom).offset(self.topInset)
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                }
                
                self.setupInvestContentViewLayout()
                
                self.setupVideoWebViewLayout()
                
                self.separatorView.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview()
                    make.top.equalTo(self.videoWebView.snp.bottom).offset(self.bottomInset)
                    make.height.equalTo(1.0)
                }
                
                self.moreInfoButton.snp.makeConstraints { (make) in
                    make.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.equalTo(self.separatorView.snp.bottom)
                    make.bottom.equalToSuperview()
                    make.height.equalTo(44.0)
                }
            }
            
            private func setupInvestContentViewLayout() {
                self.investContentView.addSubview(self.investedAmountLabel)
                self.investContentView.addSubview(self.percentLabel)
                self.investContentView.addSubview(self.progressView)
                self.investContentView.addSubview(self.investorsAmountLabel)
                self.investContentView.addSubview(self.timeLabel)
                
                let sideInset: CGFloat = 10
                let topInset: CGFloat = 10
                let bottomInset: CGFloat = 10
                
                self.investedAmountLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                self.investedAmountLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                
                self.percentLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                self.percentLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
                
                self.investorsAmountLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                self.investorsAmountLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                
                self.timeLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                self.timeLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
                
                self.investedAmountLabel.snp.makeConstraints { (make) in
                    make.top.equalToSuperview()
                    make.leading.equalToSuperview()
                }
                
                self.percentLabel.snp.makeConstraints { (make) in
                    make.top.equalToSuperview()
                    make.trailing.equalToSuperview()
                    make.leading.equalTo(self.investedAmountLabel.snp.trailing).offset(sideInset)
                }
                
                self.progressView.snp.makeConstraints { (make) in
                    make.top.equalTo(self.investedAmountLabel.snp.bottom).offset(topInset)
                    make.leading.equalTo(self.investorsAmountLabel.snp.leading)
                    make.trailing.equalTo(self.percentLabel.snp.trailing)
                }
                
                self.investorsAmountLabel.snp.makeConstraints { (make) in
                    make.top.equalTo(self.progressView.snp.bottom).offset(topInset)
                    make.leading.equalToSuperview()
                    make.bottom.equalToSuperview().inset(bottomInset)
                }
                
                self.timeLabel.snp.makeConstraints { (make) in
                    make.top.equalTo(self.progressView.snp.bottom).offset(topInset)
                    make.trailing.equalToSuperview()
                    make.leading.equalTo(self.investorsAmountLabel.snp.trailing).offset(sideInset)
                }
            }
            
            private func setupVideoWebViewLayout() {
                let topInset: CGFloat = self.isVideoWebViewHidden ? 0 : self.topInset
                let heightToWidthMultiplier: CGFloat = self.isVideoWebViewHidden ? 0 : 9.0/16.0
                
                self.videoWebView.snp.remakeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.equalTo(self.investContentView.snp.bottom).offset(topInset)
                    make.height.equalTo(self.videoWebView.snp.width).multipliedBy(heightToWidthMultiplier)
                }
            }
            
            private var isVideoWebViewHidden: Bool {
                get {
                    return self.videoWebView.isHidden
                }
                set {
                    self.videoWebView.isHidden = newValue
                    self.setupVideoWebViewLayout()
                }
            }
            
            private func showVideoWebViewIfNeeded() {
                guard self.isVideoWebViewHidden
                    else {
                        return
                }
                
                self.isVideoWebViewHidden = false
            }
            
            private func hideVideoWebViewIfNeeded() {
                guard !self.isVideoWebViewHidden
                    else {
                        return
                }
                
                self.isVideoWebViewHidden = true
            }
        }
    }
}

extension SaleDetails.DescriptionCell.View {
    enum ImageState {
        case empty
        case loaded(UIImage)
        case loading
    }
}

extension SaleDetails.Model.DescriptionCellModel.ImageState {
    var saleCellImageState: SaleDetails.DescriptionCell.View.ImageState {
        switch self {
            
        case .empty:
            return .empty
            
        case .loaded(let image):
            return .loaded(image)
            
        case .loading:
            return .loading
        }
    }
}
