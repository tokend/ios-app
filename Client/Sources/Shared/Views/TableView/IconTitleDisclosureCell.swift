import UIKit

enum IconTitleDisclosureCell {
    
    private static var titleFont: UIFont { Theme.Fonts.regularFont.withSize(17.0) }
    
    private static var iconSize: CGSize { .init(width: 23.0, height: 23.0) }
    private static var iconLeadingInset: CGFloat { 18.0 }
    private static var iconTopInset: CGFloat { 10.0 }
    private static var iconBottomInset: CGFloat { 10.0 }
    private static var titleIconOffset: CGFloat { 18.0 }
    private static var titleTopInset: CGFloat { 10.0 }
    private static var titleBottomInset: CGFloat { 11.0 }
    private static var titleTrailingInset: CGFloat { 15.0 }
    
    struct ViewModel: CellViewModel {
        
        let id: String
        let icon: TokenDUIImage
        let title: String
        
        func setup(cell: View) {
            
            cell.icon = icon
            cell.title = title
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

private extension IconTitleDisclosureCell.View {
    
    private typealias NameSpace = IconTitleDisclosureCell
    
    func commonInit() {
        setupView()
        setupIconImageView()
        setupTitleLabel()
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
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .left
        titleLabel.backgroundColor = .white
        titleLabel.lineBreakMode = .byWordWrapping
    }
    
    func setupLayout() {
        
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        
        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(NameSpace.iconSize)
            make.leading.equalToSuperview().inset(NameSpace.iconLeadingInset)
            make.top.equalToSuperview().inset(NameSpace.iconTopInset)
//            make.bottom.lessThanOrEqualToSuperview().inset(NameSpace.iconBottomInset)
        }
        
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(NameSpace.titleIconOffset)
            make.top.equalToSuperview().inset(NameSpace.titleTopInset)
//            make.bottom.equalToSuperview().inset(NameSpace.titleBottomInset)
            make.trailing.equalToSuperview().inset(NameSpace.titleTrailingInset)
        }
    }
}

// MARK:

extension IconTitleDisclosureCell.ViewModel: UITableViewCellHeightProvider {
    
    private typealias NameSpace = IconTitleDisclosureCell
    
    func height(
        with tableViewWidth: CGFloat
    ) -> CGFloat {
        
        let iconHeight: CGFloat = NameSpace.iconTopInset
            + NameSpace.iconSize.height
            + NameSpace.iconBottomInset
        
        let titleWidth: CGFloat = tableViewWidth
            - NameSpace.iconLeadingInset
            - NameSpace.iconSize.width
            - NameSpace.titleIconOffset
            - NameSpace.titleTrailingInset
        
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
