import UIKit

extension TradesList {
    
    public class AssetPairListView: UIView {
        
        // MARK: - Public properties
        
        public let backgroundViewHorizontalInset: CGFloat = 0.0
        public let backgroundViewVerticalInset: CGFloat = 10.0
        public let logoSize: CGFloat = 45.0
        public let logoHorizontalOffset: CGFloat = 20.0
        public let logoVerticalOffset: CGFloat = 15.0
        public let titlesOffset: CGFloat = 10.0
        
        public var logoLetter: String? {
            get { return self.logoLetterLabel.text }
            set { self.logoLetterLabel.text = newValue }
        }
        
        public var logoColoring: UIColor? {
            get { return self.logoLetterLabel.backgroundColor }
            set { self.logoLetterLabel.backgroundColor = newValue }
        }
        
        public var title: NSAttributedString? {
            get { return self.titleLabel.attributedText }
            set { self.titleLabel.attributedText = newValue }
        }
        
        public var subTitle: String? {
            get { return self.subTitleLabel.text }
            set { self.subTitleLabel.text = newValue }
        }
        
        // MARK: - Private properties
        
        private let backgroundView: UIView = UIView()
        private let logoLetterLabel: UILabel = UILabel()
        private let titleLabel: UILabel = UILabel()
        private let subTitleLabel: UILabel = UILabel()
        
        // MARK: -
        
        public override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.setupView()
            self.setupBackgroundView()
            self.setupLogoLetterLabel()
            self.setupTitleLabel()
            self.setupSubTitleLabel()
            self.setupLayout()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.backgroundColor = UIColor.clear
        }
        
        private func setupBackgroundView() {
            self.backgroundView.backgroundColor = Theme.Colors.contentBackgroundColor
            self.backgroundView.layer.cornerRadius = 5.0
            self.backgroundView.layer.masksToBounds = true
        }
        
        private func setupLogoLetterLabel() {
            self.logoLetterLabel.textAlignment = .center
            self.logoLetterLabel.numberOfLines = 1
            self.logoLetterLabel.textColor = Theme.Colors.contentBackgroundColor
            self.logoLetterLabel.font = Theme.Fonts.largeAssetFont
            
            self.logoLetterLabel.layer.cornerRadius = self.logoSize / 2.0
            self.logoLetterLabel.layer.masksToBounds = true
        }
        
        private func setupTitleLabel() {
            self.titleLabel.textAlignment = .left
            self.titleLabel.textColor = Theme.Colors.textOnContentBackgroundColor
            self.titleLabel.font = Theme.Fonts.largeTitleFont
            self.titleLabel.numberOfLines = 0
            self.titleLabel.setContentHuggingPriority(.required, for: .vertical)
            self.titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            self.titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        
        private func setupSubTitleLabel() {
            self.subTitleLabel.textAlignment = .left
            self.subTitleLabel.textColor = Theme.Colors.textOnContentBackgroundColor
            self.subTitleLabel.font = Theme.Fonts.plainTextFont
            self.subTitleLabel.numberOfLines = 0
            self.subTitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            self.subTitleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        
        private func setupLayout() {
            self.addSubview(self.backgroundView)
            self.backgroundView.addSubview(self.logoLetterLabel)
            self.backgroundView.addSubview(self.titleLabel)
            self.backgroundView.addSubview(self.subTitleLabel)
            
            self.backgroundView.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(self.backgroundViewHorizontalInset)
                make.top.bottom.equalToSuperview().inset(self.backgroundViewVerticalInset)
            }
            
            self.logoLetterLabel.snp.makeConstraints { (make) in
                make.leading.equalToSuperview().inset(self.logoHorizontalOffset)
                make.top.bottom.equalToSuperview().inset(self.logoVerticalOffset)
                make.width.equalTo(self.logoLetterLabel.snp.height)
                make.height.equalTo(self.logoSize)
            }
            
            self.titleLabel.snp.makeConstraints { (make) in
                make.leading.equalTo(self.logoLetterLabel.snp.trailing).offset(self.logoHorizontalOffset)
                make.trailing.equalToSuperview().inset(self.logoVerticalOffset)
                make.bottom.equalTo(self.logoLetterLabel.snp.centerY)
            }
            
            self.subTitleLabel.snp.makeConstraints { (make) in
                make.leading.trailing.equalTo(self.titleLabel)
                make.top.equalTo(self.titleLabel.snp.bottom).offset(self.titlesOffset)
            }
        }
    }
}
