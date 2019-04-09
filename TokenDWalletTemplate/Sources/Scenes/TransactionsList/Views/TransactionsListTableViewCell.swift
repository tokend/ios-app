import UIKit

enum TransactionsListTableViewCell {
    
    struct Model: CellViewModel {
        
        let identifier: UInt64
        
        let balanceId: String
        let icon: UIImage
        let iconTint: UIColor
        let title: String
        let amount: String
        let amountColor: UIColor
        let counterparty: String?
        let additionalInfo: String?
        
        func setup(cell: TransactionsListTableViewCell.View) {
            cell.icon = self.icon.withRenderingMode(.alwaysTemplate)
            cell.iconTint = self.iconTint
            cell.title = self.title
            cell.amount = self.amount
            cell.amountColor = self.amountColor
            cell.counterparty = self.counterparty
            cell.additionalInfo = self.additionalInfo
        }
    }
    
    class View: UITableViewCell {
        
        // MARK: - Private properties
        
        private let iconView: UIImageView = UIImageView()
        private let titleLabel: UILabel = UILabel()
        private let amountLabel: UILabel = UILabel()
        private let counterpartyLabel: UILabel = UILabel()
        private let additionalInfoLabel: UILabel = UILabel()
        private let labelsContainer: UIView = UIView()
        
        private let iconToSideSpace: CGFloat = 15
        private let iconSize: CGFloat = 45
        private let iconToLabelsSpace: CGFloat = 15
        
        // MARK: - Public properties
        
        public var icon: UIImage? {
            get { return self.iconView.image }
            set { self.iconView.image = newValue }
        }
        
        public var iconTint: UIColor? {
            get { return self.iconView.tintColor }
            set { self.iconView.tintColor = newValue }
        }
        
        public var title: String? {
            get { return self.titleLabel.text }
            set { self.titleLabel.text = newValue }
        }
        
        public var amount: String? {
            get { return self.amountLabel.text }
            set { self.amountLabel.text = newValue }
        }
        
        public var amountColor: UIColor? {
            get { return self.amountLabel.textColor }
            set { self.amountLabel.textColor = newValue }
        }
        
        public var counterparty: String? {
            get { return self.counterpartyLabel.text }
            set { self.counterpartyLabel.text = newValue }
        }
        
        public var additionalInfo: String? {
            get { return self.additionalInfoLabel.text }
            set { self.additionalInfoLabel.text = newValue }
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
            
            self.separatorInset = UIEdgeInsets(
                top: 0,
                left: self.iconToSideSpace + self.iconSize + self.iconToLabelsSpace,
                bottom: 0,
                right: 0
            )
        }
        
        // MARK: - Private
        
        private func commonInit() {
            self.setupView()
            self.setupIconView()
            self.setupLabelsContainer()
            self.setupTitleLabel()
            self.setupAmountLabel()
            self.setupCounterpartyLabel()
            self.setupAdditionalInfoLabel()
            
            self.setupLayout()
        }
        
        private func setupView() {
            self.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupIconView() {
            self.iconView.contentMode = .scaleAspectFit
            self.iconView.tintColor = Theme.Colors.mainColor
        }
        
        private func setupLabelsContainer() {
            self.labelsContainer.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupTitleLabel() {
            self.titleLabel.font = Theme.Fonts.plainTextFont
            self.titleLabel.textAlignment = .left
            self.titleLabel.textColor = Theme.Colors.textOnContentBackgroundColor
            self.titleLabel.backgroundColor = Theme.Colors.contentBackgroundColor
            self.titleLabel.numberOfLines = 1
        }
        
        private func setupAmountLabel() {
            self.amountLabel.font = Theme.Fonts.plainTextFont
            self.amountLabel.textAlignment = .right
            self.amountLabel.textColor = Theme.Colors.textOnContentBackgroundColor
            self.amountLabel.backgroundColor = Theme.Colors.contentBackgroundColor
            self.amountLabel.numberOfLines = 1
        }
        
        private func setupCounterpartyLabel() {
            self.counterpartyLabel.font = Theme.Fonts.smallTextFont
            self.counterpartyLabel.textAlignment = .left
            self.counterpartyLabel.textColor = Theme.Colors.sideTextOnContentBackgroundColor
            self.counterpartyLabel.backgroundColor = Theme.Colors.contentBackgroundColor
            self.counterpartyLabel.numberOfLines = 1
        }
        
        private func setupAdditionalInfoLabel() {
            self.additionalInfoLabel.font = Theme.Fonts.smallTextFont
            self.additionalInfoLabel.textAlignment = .right
            self.additionalInfoLabel.textColor = Theme.Colors.sideTextOnContentBackgroundColor
            self.additionalInfoLabel.backgroundColor = Theme.Colors.contentBackgroundColor
            self.additionalInfoLabel.numberOfLines = 1
        }
        
        private func setupLayout() {
            self.addSubview(self.iconView)
            self.addSubview(self.labelsContainer)
            
            self.labelsContainer.addSubview(self.titleLabel)
            self.labelsContainer.addSubview(self.amountLabel)
            self.labelsContainer.addSubview(self.counterpartyLabel)
            self.labelsContainer.addSubview(self.additionalInfoLabel)
            
            self.titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            self.titleLabel.setContentHuggingPriority(.required, for: .horizontal)
            self.amountLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            self.amountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            self.amountLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            self.counterpartyLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            self.additionalInfoLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            self.additionalInfoLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            
            self.iconView.snp.makeConstraints { (make) in
                make.leading.equalToSuperview().inset(self.iconToSideSpace)
                make.top.bottom.equalToSuperview().inset(20)
                make.width.height.equalTo(self.iconSize)
            }
            
            self.labelsContainer.snp.makeConstraints { (make) in
                make.trailing.equalToSuperview().inset(15)
                make.leading.equalTo(self.iconView.snp.trailing).offset(self.iconToLabelsSpace)
                make.centerY.equalTo(self.iconView.snp.centerY).offset(-1)
            }
            
            self.titleLabel.snp.makeConstraints { (make) in
                make.leading.top.equalToSuperview()
            }
            
            self.amountLabel.snp.makeConstraints { (make) in
                make.trailing.top.equalToSuperview()
                make.leading.equalTo(self.titleLabel.snp.trailing).offset(8)
            }
            
            self.counterpartyLabel.snp.makeConstraints { (make) in
                make.leading.bottom.equalToSuperview()
                make.top.equalTo(self.titleLabel.snp.bottom).offset(7)
            }
            
            self.additionalInfoLabel.snp.makeConstraints { (make) in
                make.trailing.bottom.equalToSuperview()
                make.leading.equalTo(self.counterpartyLabel.snp.trailing).offset(8)
                make.width.equalTo(self.counterpartyLabel.snp.width)
                make.top.equalTo(self.amountLabel.snp.bottom).offset(7)
            }
        }
    }
}
