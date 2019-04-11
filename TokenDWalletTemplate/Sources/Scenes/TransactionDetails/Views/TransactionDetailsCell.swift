import UIKit

enum TransactionDetailsCell {
    
    struct Model: CellViewModel {
        
        let identifier: TransactionDetails.CellIdentifier
        
        let icon: UIImage
        let title: String
        let hint: String?
        
        func setup(cell: TransactionDetailsCell.View) {
            cell.icon = self.icon.withRenderingMode(.alwaysTemplate)
            cell.title = self.title
            cell.hint = hint
        }
    }
    
    class View: UITableViewCell {
        
        // MARK: - Private properties
        
        private let iconView: UIImageView = UIImageView()
        private let titleLabel: UILabel = UILabel()
        private let hintLabel: UILabel = UILabel()
        
        private let iconSize: CGFloat = 30
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
            set { self.hintLabel.text = newValue }
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
            
            self.setupLayout()
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
            self.iconView.tintColor = Theme.Colors.mainColor
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
        
        private func setupLayout() {
            self.addSubview(self.iconView)
            self.addSubview(self.titleLabel)
            self.addSubview(self.hintLabel)
            
            self.titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            self.titleLabel.setContentHuggingPriority(.required, for: .horizontal)
            
            self.iconView.snp.makeConstraints { (make) in
                make.leading.equalToSuperview().inset(self.sideInset)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(self.iconSize)
            }
            
            self.titleLabel.snp.makeConstraints { (make) in
                make.leading.equalTo(self.iconView.snp.trailing).offset(self.sideInset)
                make.trailing.equalToSuperview().inset(self.sideInset)
                make.top.equalToSuperview().inset(self.topInset)
            }
            
            self.hintLabel.snp.makeConstraints { (make) in
                make.leading.equalTo(self.titleLabel.snp.leading)
                make.trailing.equalToSuperview().inset(self.sideInset)
                make.top.equalTo(self.titleLabel.snp.bottom).offset(self.topInset/2)
                make.bottom.equalToSuperview().inset(self.topInset)
            }
        }
    }
}
