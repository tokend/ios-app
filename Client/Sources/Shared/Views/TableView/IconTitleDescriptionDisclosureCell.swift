import UIKit

enum IconTitleDescriptionDisclosureCell {
    
    private static var titleFont: UIFont { Theme.Fonts.regularFont.withSize(17.0) }
    private static var descriptionFont: UIFont { Theme.Fonts.regularFont.withSize(15.0) }
    
    private static var iconSize: CGSize { .init(width: 23.0, height: 23.0) }
    private static var iconLeadingInset: CGFloat { 18.0 }
    private static var iconTopInset: CGFloat { 10.0 }
    private static var iconBottomInset: CGFloat { 10.0 }
    private static var titleIconOffset: CGFloat { 18.0 }
    private static var titleTopInset: CGFloat { 10.0 }
    private static var titleBottomInset: CGFloat { 11.0 }
    private static var descriptionLeadingOffset: CGFloat { 16.0 }
    private static var descriptionTrailingInset: CGFloat { 16.0 }
    
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
        }
    }
    
    class View: UITableViewCell {
        
        // MARK: Private properties
        
        private let iconImageView: UIImageView = .init()
        private let titleLabel: UILabel = .init()
        private let descriptionLabel: UILabel = .init()
        
        // MARK: Public properties
        
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
        
        // MARK:
        
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

// MARK: Private methods

private extension IconTitleDescriptionDisclosureCell.View {
    
    private typealias NameSpace = IconTitleDescriptionDisclosureCell
    
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
        accessoryType = .disclosureIndicator
        separatorInset.left = NameSpace.iconLeadingInset
            + NameSpace.iconSize.width
            + NameSpace.titleIconOffset
    }
    
    func setupIconImageView() {
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .lightGray
        iconImageView.backgroundColor = .white
    }
    
    func setupTitleLabel() {
        titleLabel.font = NameSpace.titleFont
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .left
        titleLabel.backgroundColor = .white
        titleLabel.lineBreakMode = .byWordWrapping
    }
    
    func setupDescriptionLabel() {
        descriptionLabel.font = NameSpace.titleFont
        descriptionLabel.textColor = .systemGray
        descriptionLabel.numberOfLines = 1
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
//            make.bottom.lessThanOrEqualToSuperview().inset(NameSpace.iconBottomInset)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(NameSpace.titleIconOffset)
            make.top.equalToSuperview().inset(NameSpace.titleTopInset)
            make.bottom.equalToSuperview().inset(NameSpace.titleBottomInset)
        }
        
        descriptionLabel.setContentHuggingPriority(.required, for: .horizontal)
        descriptionLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        descriptionLabel.setContentHuggingPriority(.required, for: .vertical)
        descriptionLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        descriptionLabel.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(NameSpace.descriptionLeadingOffset)
            make.trailing.equalToSuperview().inset(NameSpace.descriptionTrailingInset)
            make.centerY.equalToSuperview()
        }
    }
}

// MARK:

extension IconTitleDescriptionDisclosureCell.ViewModel: UITableViewCellHeightProvider {
    
    private typealias NameSpace = IconTitleDescriptionDisclosureCell
    
    func height(
        with tableViewWidth: CGFloat
    ) -> CGFloat {
        
        let iconHeight: CGFloat = NameSpace.iconTopInset
            + NameSpace.iconSize.height
            + NameSpace.iconBottomInset
        
        let descriptionWidth: CGFloat = description
            .size(with: NameSpace.descriptionFont)
            .width
        
        let titleWidth: CGFloat = tableViewWidth
            - NameSpace.iconLeadingInset
            - NameSpace.iconSize.width
            - NameSpace.titleIconOffset
            - NameSpace.descriptionLeadingOffset
            - descriptionWidth
            - NameSpace.descriptionTrailingInset
        
        let titleTextHeight: CGFloat = title.height(
            constraintedWidth: titleWidth,
            font: NameSpace.titleFont
        )
        
        let titleHeight: CGFloat = NameSpace.titleTopInset
            + titleTextHeight
            + NameSpace.titleBottomInset
        
        return max(iconHeight, titleHeight)
    }
}
