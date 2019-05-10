import UIKit
import RxSwift
import Nuke

extension Sales {
    
    enum SaleListCell {
        
        struct ViewModel: CellViewModel {
            
            let imageUrl: URL?
            let name: String
            let description: NSAttributedString
            
            let investedAmountText: NSAttributedString
            let investedPercentage: Float
            let investedPercentageText: NSAttributedString
            
            let isUpcomming: Bool
            let timeText: NSAttributedString
            
            let saleIdentifier: String
            let asset: String
            
            func setup(cell: View) {
                cell.imageURL = self.imageUrl
                cell.saleName = self.name
                cell.saleDescription = self.description
                
                cell.investedAmountText = self.investedAmountText
                cell.investedPercentageText = self.investedPercentageText
                cell.investedPercent = self.investedPercentage
                
                cell.isUpcoming = self.isUpcomming
                cell.timeText = self.timeText
                
                cell.identifier = self.saleIdentifier
            }
        }
        
        class View: UITableViewCell {
            
            // MARK: - Public property
            
            public var imageURL: URL? {
                didSet {
                    if let imageURL = self.imageURL {
                        Nuke.loadImage(
                            with: imageURL,
                            into: self.saleImageView
                        )
                    } else {
                        Nuke.cancelRequest(for: self.saleImageView)
                        self.saleImageView.image = nil
                    }
                }
            }
            
            public var isUpcoming: Bool = false {
                didSet {
                    if self.isUpcoming {
                        self.upcomingImageView.image = #imageLiteral(resourceName: "Upcoming image")
                    } else {
                        self.upcomingImageView.image = nil
                    }
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
            
            public var identifier: Sales.CellIdentifier = ""
            
            // MARK: - Private properties
            
            private let saleImageView: UIImageView = UIImageView()
            private let upcomingImageView: UIImageView = UIImageView()
            private let nameLabel: UILabel = UILabel()
            private let shortDescriptionLabel: UILabel = UILabel()
            private let investContenView: UIView = UIView()
            
            private var saleImageDisposable: Disposable?
            
            // Invested views
            
            private let investedAmountLabel: UILabel = UILabel()
            private let percentLabel: UILabel = UILabel()
            private let progressView: UIProgressView = UIProgressView()
            private let investorsAmountLabel: UILabel = UILabel()
            private let timeLabel: UILabel = UILabel()
            
            private let sideInset: CGFloat = 20
            private let topInset: CGFloat = 15
            private let bottomInset: CGFloat = 15
            
            // MARK: -
            
            override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
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
                self.setupSaleImageView()
                self.setupNameLabel()
                self.setupShortDescriptionLabel()
                self.setupInvestedAmountLabel()
                self.setupPercentLabel()
                self.setupProgressView()
                self.setupTimeLabel()
                
                self.setupLayout()
            }
            
            private func setupView() {
                self.backgroundColor = Theme.Colors.contentBackgroundColor
                self.selectionStyle = .none
            }
            
            private func setupSaleImageView() {
                self.saleImageView.clipsToBounds = true
                self.saleImageView.contentMode = .scaleAspectFill
                self.saleImageView.backgroundColor = Theme.Colors.containerBackgroundColor
            }
            
            private func setupNameLabel() {
                self.nameLabel.font = Theme.Fonts.largeTitleFont
                self.nameLabel.textColor = Theme.Colors.textOnContentBackgroundColor
                self.nameLabel.textAlignment = .left
                self.nameLabel.numberOfLines = 0
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
            
            private func setupLayout() {
                self.contentView.addSubview(self.saleImageView)
                self.saleImageView.addSubview(self.upcomingImageView)
                self.contentView.addSubview(self.nameLabel)
                self.contentView.addSubview(self.shortDescriptionLabel)
                self.contentView.addSubview(self.investContenView)
                
                self.saleImageView.snp.makeConstraints { (make) in
                    make.top.leading.trailing.equalToSuperview()
                    make.width.equalTo(self.saleImageView.snp.height).multipliedBy(16.0/9.0)
                }
                
                self.upcomingImageView.snp.makeConstraints { (make) in
                    make.top.trailing.equalToSuperview()
                    make.height.width.equalTo(self.saleImageView.snp.height).multipliedBy(0.5)
                }
                
                self.nameLabel.snp.makeConstraints { (make) in
                    make.top.equalTo(self.saleImageView.snp.bottom).offset(self.topInset)
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                }
                
                self.shortDescriptionLabel.snp.makeConstraints { (make) in
                    make.top.equalTo(self.nameLabel.snp.bottom).offset(self.topInset)
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                }
                
                self.investContenView.snp.makeConstraints { (make) in
                    make.top.equalTo(self.shortDescriptionLabel.snp.bottom).offset(self.topInset)
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.bottom.equalToSuperview().inset(self.bottomInset)
                }
                
                self.setupInvestedViewLayout()
            }
            
            private func setupInvestedViewLayout () {
                self.investContenView.addSubview(self.investedAmountLabel)
                self.investContenView.addSubview(self.percentLabel)
                self.investContenView.addSubview(self.progressView)
                self.investContenView.addSubview(self.investorsAmountLabel)
                self.investContenView.addSubview(self.timeLabel)
                
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
                    make.top.equalTo(self.progressView.snp.bottom).offset(topInset)
                    make.leading.equalTo(self.percentLabel.snp.trailing).offset(sideInset)
                    make.bottom.lessThanOrEqualToSuperview()
                }
            }
        }
    }
}

extension Sales.SaleListCell.View {
    enum ImageState {
        case empty
        case loaded(UIImage)
        case loading
    }
}

extension Sales.Model.SaleModel.ImageState {
    var saleCellImageState: Sales.SaleListCell.View.ImageState {
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
