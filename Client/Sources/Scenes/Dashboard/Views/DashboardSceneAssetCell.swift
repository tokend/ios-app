import UIKit

extension DashboardScene {
    enum AssetCell {
        
        private static var iconSize: CGSize { .init(width: 44.0, height: 44.0) }
        private static var iconTopInset: CGFloat { 5.0 }
        private static var iconLeadingInset: CGFloat { 18.0 }
        private static var iconBottomInset: CGFloat { 5.0 }
        private static var titleTopInset: CGFloat { 12.0 }
        private static var labelsLeadingOffset: CGFloat { 12.0 }
        private static var labelsTrailingInset: CGFloat { 16.0 }
        private static var valueTopOffset: CGFloat { 5.0 }
        private static var valueBottomInset: CGFloat { 12.0 }
        
        private static var titleColor: UIColor { Theme.Colors.dark }
        private static var titleFont: UIFont { Theme.Fonts.semiboldFont.withSize(14.0) }
        private static var valueColor: UIColor { Theme.Colors.dark }
        private static var valueFont: UIFont { Theme.Fonts.regularFont.withSize(12.0) }
        private static var abbreviationFont: UIFont { Theme.Fonts.regularFont.withSize(24.0) }
        private static var cellBackgroundColor: UIColor { Theme.Colors.white }
        
        struct ViewModel: CellViewModel {
            let id: String
            let icon: TokenDUIImage?
            let abbreviation: String
            let title: String
            let value: String
            
            func setup(cell: View) {
                cell.icon = icon
                cell.abbreviation = abbreviation
                cell.title = title
                cell.value = value
            }
            
            var hashValue: Int {
                id.hashValue
            }
            
            func hash(into hasher: inout Hasher) {
                hasher.combine(id)
            }
            
            public static func == (lhs: ViewModel, rhs: ViewModel) -> Bool {
                
                return lhs.icon == rhs.icon
                    && lhs.abbreviation == rhs.abbreviation
                    && lhs.title == rhs.title
                    && lhs.value == rhs.value
            }
        }
        
        class View: UITableViewCell {
            
            // MARK: - Private properties

            private let iconView: UIImageView = .init()
            private let abbreviationLabel: UILabel = .init()
            private let titleLabel: UILabel = .init()
            private let valueLabel: UILabel = .init()
            
            // MARK: - Public Properties

            public var icon: TokenDUIImage? {
                didSet {
                    iconView.setTokenDUIImage(icon)
                }
            }
            
            public var abbreviation: String? {
                get { abbreviationLabel.text }
                set { abbreviationLabel.text = newValue }
            }
            
            public var title: String? {
                get { titleLabel.text }
                set { titleLabel.text = newValue }
            }
            
            public var value: String? {
                get { valueLabel.text }
                set { valueLabel.text = newValue }
            }
            
            // MARK: -
            
            override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
                super.init(style: style, reuseIdentifier: reuseIdentifier)
                
                commonInit()
            }
            
            required init?(coder: NSCoder) {
                super.init(coder: coder)
                
                commonInit()
            }
        }
    }
}

// MARK: - Private methods

private extension DashboardScene.AssetCell.View {
    typealias NameSpace = DashboardScene.AssetCell
    
    func commonInit() {
        setupView()
        setupIconImageView()
        setupAbbreviationLabel()
        setupTitleLabel()
        setupValueLabel()
        setupLayout()
    }
    
    func setupView() {
        backgroundColor = NameSpace.cellBackgroundColor
        selectionStyle = .none
        separatorInset.left = NameSpace.iconLeadingInset
            + NameSpace.iconSize.width
            + NameSpace.labelsLeadingOffset
    }
    
    func setupIconImageView() {
        iconView.contentMode = .scaleAspectFill
        iconView.tintColor = .lightGray
        iconView.backgroundColor = .clear
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = NameSpace.iconSize.width / 2
    }
    
    func setupAbbreviationLabel() {
        abbreviationLabel.font = NameSpace.abbreviationFont
        abbreviationLabel.textColor = .white
        abbreviationLabel.numberOfLines = 1
        abbreviationLabel.textAlignment = .center
        abbreviationLabel.backgroundColor = .abbreviationColor()
        abbreviationLabel.lineBreakMode = .byWordWrapping
        abbreviationLabel.layer.cornerRadius = NameSpace.iconSize.height / 2.0
        abbreviationLabel.layer.masksToBounds = true
    }
    
    func setupTitleLabel() {
        titleLabel.font = NameSpace.titleFont
        titleLabel.textColor = NameSpace.titleColor
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .left
        titleLabel.backgroundColor = NameSpace.cellBackgroundColor
        titleLabel.lineBreakMode = .byCharWrapping
    }
    
    func setupValueLabel() {
        valueLabel.font = NameSpace.valueFont
        valueLabel.textColor = NameSpace.valueColor
        valueLabel.numberOfLines = 0
        valueLabel.textAlignment = .left
        valueLabel.backgroundColor = NameSpace.cellBackgroundColor
        valueLabel.lineBreakMode = .byWordWrapping
    }
    
    func setupLayout() {
        contentView.addSubview(abbreviationLabel)
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)
        
        iconView.snp.makeConstraints { (make) in
            make.size.equalTo(NameSpace.iconSize)
            make.leading.equalToSuperview().inset(NameSpace.iconLeadingInset)
            make.top.greaterThanOrEqualToSuperview().inset(NameSpace.iconTopInset)
            make.bottom.lessThanOrEqualToSuperview().inset(NameSpace.iconBottomInset)
            make.centerY.equalToSuperview()
        }
        
        abbreviationLabel.snp.makeConstraints { (make) in
            make.edges.equalTo(iconView)
        }
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(NameSpace.titleTopInset)
            make.leading.equalTo(iconView.snp.trailing).offset(NameSpace.labelsLeadingOffset)
            make.trailing.equalToSuperview().inset(NameSpace.labelsTrailingInset)
        }
        
        valueLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(NameSpace.valueTopOffset)
            make.leading.equalTo(iconView.snp.trailing).offset(NameSpace.labelsLeadingOffset)
            make.trailing.equalToSuperview().inset(NameSpace.labelsTrailingInset)
            make.bottom.equalToSuperview().inset(NameSpace.valueBottomInset)
        }
    }
}

extension DashboardScene.AssetCell.ViewModel: UITableViewCellHeightProvider {
    private typealias NameSpace = DashboardScene.AssetCell
    
    func height(
        with tableViewWidth: CGFloat
    ) -> CGFloat {
        
        let iconHeight: CGFloat = NameSpace.iconTopInset
            + NameSpace.iconSize.height
            + NameSpace.iconBottomInset
        
        let titleHeight: CGFloat = String.singleLineHeight(
            font: NameSpace.titleFont
        )
        
        let valueHeight: CGFloat = String.singleLineHeight(
            font: NameSpace.valueFont
        )
        
        let textHeight: CGFloat = NameSpace.titleTopInset
            + titleHeight
            + NameSpace.valueTopOffset
            + valueHeight
            + NameSpace.valueBottomInset
        
        return max(iconHeight, textHeight)
    }
}
