import UIKit

enum TokenDetailsTokenSummaryCell {
    struct Model: CellViewModel {
        let title: String
        let value: String
        
        func setup(cell: TokenDetailsTokenSummaryCell.View) {
            cell.title = self.title
            cell.value = self.value
        }
    }
    
    class View: UITableViewCell {
        
        // MARK: - Private properties
        
        private let titleLabel: UILabel = UILabel()
        private let valueLabel: UILabel = UILabel()
        
        // MARK: - Public properties
        
        public var title: String = "" {
            didSet { self.titleLabel.text = self.title }
        }
        public var value: String = "" {
            didSet { self.valueLabel.text = self.value }
        }
        
        // MARK: - Initializers
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            self.commonInit()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            self.separatorInset = UIEdgeInsets(top: 0, left: self.titleLabel.frame.origin.x, bottom: 0, right: 0)
        }
        
        // MARK: - Private
        
        private func commonInit() {
            self.setupView()
            self.setupTitleLabel()
            self.setupValueLabel()
            
            self.setupLayout()
        }
        
        private func setupView() {
            self.backgroundColor = Theme.Colors.contentBackgroundColor
            self.selectionStyle = .none
        }
        
        private func setupTitleLabel() {
            self.titleLabel.font = Theme.Fonts.plainTextFont
            self.titleLabel.textColor = Theme.Colors.textOnContentBackgroundColor
            self.titleLabel.textAlignment = .left
            self.titleLabel.numberOfLines = 1
        }
        
        private func setupValueLabel() {
            self.valueLabel.font = Theme.Fonts.plainTextFont
            self.valueLabel.textColor = Theme.Colors.textOnContentBackgroundColor
            self.valueLabel.textAlignment = .left
            self.valueLabel.numberOfLines = 1
        }
        
        private func setupLayout() {
            self.addSubview(self.titleLabel)
            self.addSubview(self.valueLabel)
            
            self.valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            self.valueLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            
            let sideInset: CGFloat = 15
            let topInset: CGFloat = 11
            let bottomInset: CGFloat = 12
            
            self.titleLabel.snp.makeConstraints { (make) in
                make.left.equalToSuperview().inset(sideInset)
                make.top.equalToSuperview().inset(topInset)
                make.bottom.equalToSuperview().inset(bottomInset)
            }
            
            self.valueLabel.snp.makeConstraints { (make) in
                make.right.equalToSuperview().inset(sideInset)
                make.top.equalToSuperview().inset(topInset)
                make.bottom.equalToSuperview().inset(bottomInset)
                make.left.equalTo(self.titleLabel.snp.right).offset(sideInset)
            }
        }
    }
}
