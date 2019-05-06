import UIKit
import MarkdownView
import Nuke
import RxSwift
import WebKit

extension SaleDetails {
    
    enum OverviewTab {
        
        struct ViewModel {
            
            let imageUrl: URL?
            let name: String
            let description: NSAttributedString
            
            let youtubeVideoUrl: URL?
            
            let investedAmountText: NSAttributedString
            let investedPercentage: Float
            let investedPercentageText: NSAttributedString
            
            let timeText: NSAttributedString
            
            let overviewContent: String?
            
            let identifier: TabIdentifier
            
            func setup(tab: OverviewTab.View) {
                tab.imageURL = self.imageUrl
                tab.saleName = self.name
                tab.saleDescription = self.description
                
                tab.youtubeVideoURL = self.youtubeVideoUrl
                
                tab.investedAmountText = self.investedAmountText
                tab.investedPercentageText = self.investedPercentageText
                tab.investedPercent = self.investedPercentage
                
                tab.timeText = self.timeText
                
                tab.overviewContent = self.overviewContent
                
                tab.identifier = self.identifier
            }
        }
        
        class View: UIView {
            
            // MARK: - Public property
            
            public var imageURL: URL? {
                didSet {
                    if let imageURL = self.imageURL {
                        Nuke.loadImage(
                            with: imageURL,
                            into: self.assetImageView
                        )
                    } else {
                        Nuke.cancelRequest(for: self.assetImageView)
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
            
            public var saleDescription: NSAttributedString? {
                get { return self.shortDescriptionLabel.attributedText }
                set { self.shortDescriptionLabel.attributedText = newValue }
            }
            
            public var investedAmountText: NSAttributedString? {
                get { return self.investedAmountLabel.attributedText }
                set { self.investedAmountLabel.attributedText = newValue }
            }
            
            public var investedPercent: Float {
                get { return self.progressView.progress }
                set { self.progressView.progress = newValue }
            }
            
            public var investedPercentageText: NSAttributedString? {
                get { return self.percentLabel.attributedText }
                set { self.percentLabel.attributedText = newValue }
            }
            
            public var timeText: NSAttributedString? {
                get { return self.timeLabel.attributedText }
                set { self.timeLabel.attributedText = newValue }
            }
            
            public var overviewContent: String? {
                didSet {
                    self.overviewContentView.load(markdown: self.overviewContent)
                }
            }
            
            public var identifier: TabIdentifier?
            
            // MARK: - Private properties
            
            private let disposeBag = DisposeBag()
            
            private let iconSize: CGFloat = 45
            
            private let scrollView: UIScrollView = UIScrollView()
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
            private let timeLabel: UILabel = UILabel()
            
            private let overviewContentView: MarkdownView = MarkdownView()
            private var overviewContentHeight: CGFloat = 0.0 {
                didSet {
                    let newValue = self.overviewContentHeight
                    guard newValue != oldValue else {
                        return
                    }
                    
                    self.updateOverviewContentHeight(newValue)
                }
            }
            
            private let sideInset: CGFloat = 20.0
            private let markdownSideInset: CGFloat = 4.0
            private let topInset: CGFloat = 15.0
            private let bottomInset: CGFloat = 15.0
            
            // MARK: -
            
            override init(frame: CGRect) {
                super.init(frame: frame)
                
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
                self.setupScrollView()
                self.setupAssetImageView()
                self.setupNameLabel()
                self.setupShortDescriptionLabel()
                self.setupInvestedAmountLabel()
                self.setupPercentLabel()
                self.setupProgressView()
                self.setupTimeLabel()
                self.setupVideoWebView()
                self.setupOverviewContentView()
                
                self.setupLayout()
            }
            
            private func setupView() {
                self.backgroundColor = Theme.Colors.contentBackgroundColor
            }
            
            private func setupScrollView() {
                self.scrollView.backgroundColor = Theme.Colors.contentBackgroundColor
            }
            
            private func setupAssetImageView() {
                self.assetImageView.contentMode = .scaleAspectFill
                self.assetImageView.clipsToBounds = true
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
                self.shortDescriptionLabel.font = Theme.Fonts.plainTextFont
                self.shortDescriptionLabel.textColor = Theme.Colors.textOnContentBackgroundColor
                self.shortDescriptionLabel.textAlignment = .left
                self.shortDescriptionLabel.numberOfLines = 0
                self.shortDescriptionLabel.lineBreakMode = .byWordWrapping
            }
            
            private func setupInvestedAmountLabel() {
                self.investedAmountLabel.font = Theme.Fonts.smallTextFont
                self.investedAmountLabel.textColor = Theme.Colors.accentColor
                self.investedAmountLabel.textAlignment = .left
                self.investedAmountLabel.numberOfLines = 2
            }
            
            private func setupPercentLabel() {
                self.percentLabel.font = Theme.Fonts.smallTextFont
                self.percentLabel.textColor = Theme.Colors.textOnContentBackgroundColor
                self.percentLabel.textAlignment = .left
                self.percentLabel.numberOfLines = 2
            }
            
            private func setupProgressView() {
                self.progressView.tintColor = Theme.Colors.accentColor
            }
            
            private func setupTimeLabel() {
                self.timeLabel.font = Theme.Fonts.smallTextFont
                self.timeLabel.textColor = Theme.Colors.accentColor
                self.timeLabel.textAlignment = .left
                self.timeLabel.numberOfLines = 2
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
            
            private func setupOverviewContentView() {
                self.overviewContentView.onRendered = { [weak self] (height) in
                    self?.overviewContentHeight = height
                }
            }
            
            private func setupLayout() {
                self.addSubview(self.scrollView)
                self.scrollView.addSubview(self.assetImageView)
                self.scrollView.addSubview(self.nameLabel)
                self.scrollView.addSubview(self.shortDescriptionLabel)
                self.scrollView.addSubview(self.investContentView)
                self.scrollView.addSubview(self.videoWebView)
                self.scrollView.addSubview(self.overviewContentView)
                
                self.scrollView.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
                
                self.assetImageView.snp.makeConstraints { (make) in
                    make.top.leading.trailing.equalToSuperview()
                    make.width.equalTo(self.assetImageView.snp.height).multipliedBy(16.0/9.0)
                    make.width.equalTo(self.snp.width)
                }
                
                self.nameLabel.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.equalTo(self.assetImageView.snp.bottom).offset(self.topInset)
                }
                
                self.shortDescriptionLabel.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.equalTo(self.nameLabel.snp.bottom).offset(self.topInset)
                }
                
                self.investContentView.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.equalTo(self.shortDescriptionLabel.snp.bottom).offset(self.topInset)
                }
                
                self.setupInvestContentViewLayout()
                
                self.setupVideoWebViewLayout()
                
                self.updateOverviewContentHeight(0.0)
            }
            
            private func setupInvestContentViewLayout() {
                self.investContentView.addSubview(self.investedAmountLabel)
                self.investContentView.addSubview(self.percentLabel)
                self.investContentView.addSubview(self.progressView)
                self.investContentView.addSubview(self.timeLabel)
                
                let sideInset: CGFloat = 40
                let topInset: CGFloat = 10
                self.investedAmountLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                self.investedAmountLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                
                self.percentLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                self.percentLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
                
                self.progressView.snp.makeConstraints { (make) in
                    make.leading.trailing.top.equalToSuperview()
                }
                
                self.investedAmountLabel.snp.makeConstraints { (make) in
                    make.leading.equalTo(self.progressView.snp.leading)
                    make.top.equalTo(self.progressView.snp.bottom).offset(topInset)
                    make.bottom.lessThanOrEqualToSuperview()
                }
                
                self.percentLabel.snp.makeConstraints { (make) in
                    make.leading.equalTo(self.investedAmountLabel.snp.trailing).offset(sideInset)
                    make.top.equalTo(self.progressView.snp.bottom).offset(topInset)
                    make.bottom.lessThanOrEqualToSuperview()
                }
                
                self.timeLabel.snp.makeConstraints { (make) in
                    make.leading.equalTo(self.percentLabel.snp.trailing).offset(sideInset)
                    make.top.equalTo(self.progressView.snp.bottom).offset(topInset)
                    make.bottom.lessThanOrEqualToSuperview()
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
            
            private func updateOverviewContentHeight(_ height: CGFloat) {
                self.overviewContentView.snp.remakeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.markdownSideInset)
                    make.top.equalTo(self.videoWebView.snp.bottom).offset(self.topInset)
                    make.bottom.equalToSuperview().inset(self.bottomInset)
                    make.height.equalTo(height)
                }
            }
        }
    }
}

extension SaleDetails.OverviewTab.View {
    
    enum ImageState {
        case empty
        case loaded(UIImage)
        case loading
    }
}

extension SaleDetails.Model.OverviewTabModel.ImageState {
    
    var saleTabImageState: SaleDetails.OverviewTab.View.ImageState {
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
