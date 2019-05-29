import UIKit

enum TransactionDetailsCell {
    
    struct Model: CellViewModel {
        
        let identifier: TransactionDetails.CellIdentifier
        
        let icon: UIImage
        let title: String
        let hint: String?
        let isSeparatorHidden: Bool
        var isTruncatable: Bool
        
        func setup(cell: TransactionDetailsCell.View) {
            cell.icon = self.icon.withRenderingMode(.alwaysTemplate)
            cell.title = self.title
            cell.hint = self.hint
            cell.isSeparatorHidden = self.isSeparatorHidden
            cell.isTruncatable = self.isTruncatable
        }
    }
    
    class View: UITableViewCell {
        
        // MARK: - Private properties
        
        private let iconView: UIImageView = UIImageView()
        private let titleLabel: UILabel = UILabel()
        private let hintLabel: UILabel = UILabel()
        private let separator: UIView = UIView()
        
        private let iconSize: CGFloat = 24
        private let sideInset: CGFloat = 20
        private let topInset: CGFloat = 15
        
        // MARK: - Public properties
        
        public var icon: UIImage? {
            get { return self.iconView.image }
            set { self.iconView.image = newValue }
        }
        
        public var title: String? {
            get { return self.titleLabel.text }
            set { self.titleLabel.text = newValue }
        }
        
        public var hint: String? {
            get { return self.hintLabel.text }
            set {
                self.hintLabel.text = newValue
                self.updateLayout()
            }
        }
        
        public var isSeparatorHidden: Bool {
            get { return self.separator.isHidden }
            set { self.separator.isHidden = newValue }
        }
        
        public var isTruncatable: Bool = false {
            didSet {
                self.updateTitleTruncatability()
            }
        }
        
        // MARK: -
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            self.commonInit()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - Private
        
        private func commonInit() {
            self.setupView()
            self.setupIconView()
            self.setupTitleLabel()
            self.setupHintLabel()
            self.setupSeparator()
            
            self.setupLayout()
        }
        
        private func updateTitleTruncatability() {
            if self.isTruncatable {
                self.titleLabel.numberOfLines = 1
                self.titleLabel.lineBreakMode = .byTruncatingMiddle
            } else {
                self.titleLabel.numberOfLines = 0
            }
        }
        
        private func setupView() {
            self.backgroundColor = Theme.Colors.contentBackgroundColor
            self.separatorInset = UIEdgeInsets(
                top: 0.0,
                left: self.sideInset * 2 + self.iconSize,
                bottom: 0.0,
                right: 0.0
            )
            self.selectionStyle = .none
        }
        
        private func setupIconView() {
            self.iconView.contentMode = .scaleAspectFit
            self.iconView.tintColor = Theme.Colors.darkAccentColor
        }
        
        private func setupTitleLabel() {
            self.titleLabel.font = Theme.Fonts.plainTextFont
            self.titleLabel.textAlignment = .left
            self.titleLabel.textColor = Theme.Colors.textOnContentBackgroundColor
            self.titleLabel.backgroundColor = Theme.Colors.contentBackgroundColor
            self.titleLabel.numberOfLines = 0
        }
        
        private func setupHintLabel() {
            self.hintLabel.font = Theme.Fonts.smallTextFont
            self.hintLabel.textAlignment = .left
            self.hintLabel.textColor = Theme.Colors.sideTextOnContentBackgroundColor
            self.hintLabel.backgroundColor = Theme.Colors.contentBackgroundColor
            self.hintLabel.numberOfLines = 1
        }
        
        private func setupSeparator() {
            self.separator.backgroundColor = Theme.Colors.separatorOnContentBackgroundColor
        }
        
        private func setupLayout() {
            self.addSubview(self.iconView)
            self.addSubview(self.titleLabel)
            self.addSubview(self.separator)
            
            self.titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            self.titleLabel.setContentHuggingPriority(.required, for: .horizontal)
            
            self.iconView.snp.makeConstraints { (make) in
                make.leading.equalToSuperview().inset(self.sideInset)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(self.iconSize)
            }
            
            self.separator.snp.makeConstraints { (make) in
                make.leading.equalToSuperview().inset(self.sideInset * 2 + self.iconSize)
                make.trailing.bottom.equalToSuperview()
                make.height.equalTo(1.0/UIScreen.main.scale)
            }
            
            self.updateLayout()
        }
        
        private func updateLayout() {
            if let hint = self.hint,
                !hint.isEmpty {
                
                self.addSubview(self.hintLabel)
                self.titleLabel.snp.remakeConstraints { (make) in
                    make.leading.equalTo(self.iconView.snp.trailing).offset(self.sideInset)
                    make.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.equalToSuperview().inset(self.topInset)
                }
                
                self.hintLabel.snp.makeConstraints { (make) in
                    make.leading.trailing.equalTo(self.titleLabel)
                    make.top.equalTo(self.titleLabel.snp.bottom).offset(self.topInset/2)
                    make.bottom.equalToSuperview().inset(self.topInset)
                }
            } else {
                self.hintLabel.removeFromSuperview()
                self.titleLabel.snp.remakeConstraints { (make) in
                    make.leading.equalTo(self.iconView.snp.trailing).offset(self.sideInset)
                    make.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.bottom.equalToSuperview().inset(self.topInset)
                }
            }
            self.setNeedsLayout()
        }
    }
}
