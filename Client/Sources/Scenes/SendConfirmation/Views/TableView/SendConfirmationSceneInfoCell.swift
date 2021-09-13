import UIKit

extension SendConfirmationScene {
    enum InfoCell {
        
        private static var titleFont: UIFont { Theme.Fonts.semiboldFont.withSize(12.0) }
        private static var descriptionFont: UIFont { Theme.Fonts.regularFont.withSize(16.0) }
        
        private static var iconSize: CGSize { .init(width: 24.0, height: 24.0) }
        private static var iconLeadingInset: CGFloat { 18.0 }
        private static var iconTopInset: CGFloat { 10.0 }
        private static var iconBottomInset: CGFloat { 10.0 }
        private static var titleTopInset: CGFloat { 10.0 }
        private static var labelsIconOffset: CGFloat { 18.0 }
        private static var labelsTrailingInset: CGFloat { 16.0 }
        private static var descriptionTopOffset: CGFloat { 5.0 }
        private static var descriptionBottomInset: CGFloat { 10.0 }
        
        struct ViewModel: CellViewModel {
            
            let id: String
            let icon: TokenDUIImage
            let title: String
            let description: String
            
            func setup(cell: View) {
                
                cell.icon = icon
                cell.title = title
                cell.descriptionValue = description
            }
            
            var hashValue: Int {
                id.hashValue
            }
            
            func hash(into hasher: inout Hasher) {
                hasher.combine(id)
            }
            
            public static func == (lhs: ViewModel, rhs: ViewModel) -> Bool {
                
                return lhs.icon == rhs.icon
                    && lhs.title == rhs.title
                    && lhs.description == rhs.description
            }
        }
        
        class View: UITableViewCell {
            
            // MARK: - Private properties
            
            private let iconImageView: UIImageView = .init()
            private let titleLabel: UILabel = .init()
            private let descriptionLabel: UILabel = .init()
            
            // MARK: - Public properties
            
            public var icon: TokenDUIImage? {
                didSet {
                    iconImageView.setTokenDUIImage(icon)
                }
            }
            
            public var title: String? {
                get { titleLabel.text }
                set { titleLabel.text = newValue }
            }
            
            public var descriptionValue: String? {
                get { descriptionLabel.text }
                set { descriptionLabel.text = newValue }
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

private extension SendConfirmationScene.InfoCell.View {
    
    private typealias NameSpace = SendConfirmationScene.InfoCell
    
    func commonInit() {
        setupView()
        setupIconImageView()
        setupTitleLabel()
        setupDescriptionLabel()
        setupLayout()
    }
    
    func setupView() {
        selectionStyle = .none
        backgroundColor = .white
        contentView.backgroundColor = .white
        separatorInset.left = NameSpace.iconLeadingInset
            + NameSpace.iconSize.width
            + NameSpace.labelsIconOffset
    }
    
    func setupIconImageView() {
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .lightGray
        iconImageView.backgroundColor = .white
    }
    
    func setupTitleLabel() {
        titleLabel.font = NameSpace.titleFont
        titleLabel.textColor = Theme.Colors.grey
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .left
        titleLabel.backgroundColor = .white
        titleLabel.lineBreakMode = .byWordWrapping
    }
    
    func setupDescriptionLabel() {
        descriptionLabel.font = NameSpace.descriptionFont
        descriptionLabel.textColor = Theme.Colors.dark
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .left
        descriptionLabel.backgroundColor = .white
        descriptionLabel.lineBreakMode = .byWordWrapping
    }
    
    func setupLayout() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        
        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(NameSpace.iconSize)
            make.leading.equalToSuperview().inset(NameSpace.iconLeadingInset)
            make.top.equalToSuperview().inset(NameSpace.iconTopInset)
            make.bottom.lessThanOrEqualToSuperview().inset(NameSpace.iconBottomInset)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(NameSpace.titleTopInset)
            make.leading.equalTo(iconImageView.snp.trailing).offset(NameSpace.labelsIconOffset)
            make.trailing.equalToSuperview().inset(NameSpace.labelsTrailingInset)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(NameSpace.descriptionTopOffset)
            make.leading.equalTo(iconImageView.snp.trailing).offset(NameSpace.labelsIconOffset)
            make.trailing.equalToSuperview().inset(NameSpace.labelsTrailingInset)
            make.bottom.equalToSuperview().inset(NameSpace.descriptionBottomInset)
        }
    }
}

// MARK: - UITableViewCellHeightProvider

extension SendConfirmationScene.InfoCell.ViewModel: UITableViewCellHeightProvider {
    
    private typealias NameSpace = SendConfirmationScene.InfoCell
    
    func height(with tableViewWidth: CGFloat) -> CGFloat {
        
        let iconHeight: CGFloat = NameSpace.iconTopInset
            + NameSpace.iconSize.height
            + NameSpace.iconBottomInset
        
        let descriptionAvailableWidth: CGFloat = tableViewWidth
            - NameSpace.iconLeadingInset
            - NameSpace.iconSize.width
            - NameSpace.labelsIconOffset
            - NameSpace.labelsTrailingInset
        
        let titleHeight: CGFloat = String.singleLineHeight(font: NameSpace.titleFont)
        
        let descriptionHeight: CGFloat = description.height(
            constraintedWidth: descriptionAvailableWidth,
            font: NameSpace.descriptionFont
        )
        
        let labelsHeight: CGFloat = NameSpace.titleTopInset
            + titleHeight
            + NameSpace.descriptionTopOffset
            + descriptionHeight
            + NameSpace.descriptionBottomInset
        
        return max(iconHeight, labelsHeight)
    }
}
