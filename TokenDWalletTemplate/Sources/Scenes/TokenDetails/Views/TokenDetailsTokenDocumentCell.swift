import UIKit

enum TokenDetailsTokenDocumentCell {
    struct Model: CellViewModel {
        let icon: UIImage
        let name: String
        let link: URL
        
        func setup(cell: TokenDetailsTokenDocumentCell.View) {
            cell.icon = self.icon
            cell.title = self.name
        }
    }
    
    class View: UITableViewCell {
        
        // MARK: - Private properties
        
        private let iconView: UIImageView = UIImageView()
        private let titleLabel: UILabel = UILabel()
        private let iconViewSize: CGFloat = 36
        
        // MARK: - Public properties
        
        public var icon: UIImage? = nil {
            didSet { self.iconView.image = self.icon }
        }
        public var title: String = "" {
            didSet { self.titleLabel.text = self.title }
        }
        
        // MARK: -
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            self.commonInit()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            self.separatorInset = UIEdgeInsets(top: 0, left: self.iconView.frame.origin.x, bottom: 0, right: 0)
        }
        
        // MARK: - Private
        
        private func commonInit() {
            self.setupView()
            self.setupIconView()
            self.setupTitleLabel()
            
            self.setupLayout()
        }
        
        private func setupView() {
            self.backgroundColor = Theme.Colors.contentBackgroundColor
            self.selectionStyle = .none
        }
        
        private func setupIconView() {
            self.iconView.contentMode = .scaleAspectFit
            self.iconView.tintColor = Theme.Colors.iconColor
        }
        
        private func setupTitleLabel() {
            self.titleLabel.textColor = Theme.Colors.textOnContentBackgroundColor
            self.titleLabel.font = Theme.Fonts.plainTextFont
            self.titleLabel.textAlignment = .left
            self.titleLabel.numberOfLines = 1
        }
        
        private func setupLayout() {
            self.addSubview(self.iconView)
            self.addSubview(self.titleLabel)
            
            self.iconView.snp.makeConstraints { (make) in
                make.leading.equalToSuperview().inset(15)
                make.height.equalTo(self.iconViewSize)
                make.width.equalTo(self.iconViewSize)
                make.top.equalToSuperview().inset(16)
                make.bottom.equalToSuperview().inset(16)
            }
            self.titleLabel.snp.makeConstraints { (make) in
                make.trailing.equalToSuperview().inset(15)
                make.top.greaterThanOrEqualToSuperview().inset(11)
                make.bottom.lessThanOrEqualToSuperview().inset(12)
                make.leading.equalTo(self.iconView.snp.trailing).offset(15)
                make.centerY.equalToSuperview().inset(-0.5)
            }
        }
    }
}
