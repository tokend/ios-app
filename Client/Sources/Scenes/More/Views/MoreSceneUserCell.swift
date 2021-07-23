import UIKit

extension MoreScene {
    
    enum UserCell {
        
        private static var abbreviationFont: UIFont { Theme.Fonts.regularFont.withSize(23.0) }
        private static var nameFont: UIFont { Theme.Fonts.regularFont.withSize(21.0) }
        private static var accountTypeFont: UIFont { Theme.Fonts.regularFont.withSize(13.0) }
        
        private static var avatarSize: CGSize { .init(width: 58.0, height: 58.0) }
        private static var avatarLeadingInset: CGFloat { 15.0 }
        private static var avatarTopInset: CGFloat { 9.0 }
        private static var avatarBottomInset: CGFloat { 10.0 }
        private static var nameAvatarOffset: CGFloat { 15.0 }
        private static var nameTopInset: CGFloat { 13.5 }
        private static var nameTrailingInset: CGFloat { 15.0 }
        private static var accountTypeAvatarOffset: CGFloat { 14.0 }
        private static var accountTypeNameOffset: CGFloat { 4.5 }
        private static var accountTypeBottomInset: CGFloat { 17.0 }
        private static var accountTypeTrailingInset: CGFloat { 15.0 }
        
        struct ViewModel: CellViewModel {
            
            let id: String
            let avatar: TokenDUIImage?
            let abbreviation: String
            let name: String
            let accountType: String
            
            func setup(cell: View) {
                
                cell.avatar = avatar
                cell.abbreviation = abbreviation
                cell.name = name
                cell.accountType = accountType
            }
            
            var hashValue: Int {
                id.hashValue
            }

            func hash(into hasher: inout Hasher) {
                hasher.combine(id)
            }

            public static func == (lhs: ViewModel, rhs: ViewModel) -> Bool {

                return lhs.avatar == rhs.avatar
                    && lhs.name == rhs.name
                    && lhs.accountType == rhs.accountType
            }
        }
        
        class View: UITableViewCell {
            
            // MARK: Private properties
            
            private let avatarImageView: UIImageView = .init()
            private let abbreviationLabel: UILabel = .init()
            private let nameLabel: UILabel = .init()
            private let accountTypeLabel: UILabel = .init()
            
            // MARK: Public properties
            
            public var avatar: TokenDUIImage? {
                didSet {
                    avatarImageView.setTokenDUIImage(avatar)
                }
            }
            
            public var abbreviation: String? {
                get { abbreviationLabel.text }
                set { abbreviationLabel.text = newValue }
            }
            
            public var name: String? {
                get { nameLabel.text }
                set { nameLabel.text = newValue }
            }
            
            public var accountType: String? {
                get { accountTypeLabel.text }
                set { accountTypeLabel.text = newValue }
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
}

// MARK: Private methods

private extension MoreScene.UserCell.View {
    
    private typealias NameSpace = MoreScene.UserCell
    
    func commonInit() {
        setupView()
        setupAvatarImageView()
        setupAbbreviationLabel()
        setupNameLabel()
        setupAccountTypeLabel()
        setupLayout()
    }
    
    func setupView() {
        selectionStyle = .none
        backgroundColor = .white
        contentView.backgroundColor = .white
    }
    
    func setupAvatarImageView() {
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = NameSpace.avatarSize.height / 2.0
        avatarImageView.layer.masksToBounds = true
        avatarImageView.backgroundColor = .clear
    }
    
    func setupAbbreviationLabel() {
        abbreviationLabel.font = NameSpace.abbreviationFont
        abbreviationLabel.textColor = .white
        abbreviationLabel.numberOfLines = 1
        abbreviationLabel.textAlignment = .center
        abbreviationLabel.backgroundColor = .gray
        abbreviationLabel.lineBreakMode = .byWordWrapping
        abbreviationLabel.layer.cornerRadius = NameSpace.avatarSize.height / 2.0
        abbreviationLabel.layer.masksToBounds = true
    }
    
    func setupNameLabel() {
        nameLabel.font = NameSpace.nameFont
        nameLabel.textColor = .black
        nameLabel.numberOfLines = 1
        nameLabel.textAlignment = .left
        nameLabel.backgroundColor = .white
        nameLabel.lineBreakMode = .byWordWrapping
    }
    
    func setupAccountTypeLabel() {
        accountTypeLabel.font = NameSpace.accountTypeFont
        accountTypeLabel.textColor = .black
        accountTypeLabel.numberOfLines = 1
        accountTypeLabel.textAlignment = .left
        accountTypeLabel.backgroundColor = .white
        accountTypeLabel.lineBreakMode = .byWordWrapping
    }
    
    func setupLayout() {
        
        contentView.addSubview(abbreviationLabel)
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(accountTypeLabel)
        
        avatarImageView.snp.makeConstraints { make in
            make.size.equalTo(NameSpace.avatarSize)
            make.leading.equalToSuperview().inset(NameSpace.avatarLeadingInset)
            make.top.equalToSuperview().inset(NameSpace.avatarTopInset)
            make.bottom.equalToSuperview().inset(NameSpace.avatarBottomInset)
        }
        
        abbreviationLabel.snp.makeConstraints { make in
            make.edges.equalTo(avatarImageView)
        }
        
        nameLabel.setContentHuggingPriority(.required, for: .vertical)
        nameLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(NameSpace.nameAvatarOffset)
            make.top.equalToSuperview().inset(NameSpace.nameTopInset)
            make.trailing.equalToSuperview().inset(NameSpace.nameTrailingInset)
        }
        
        accountTypeLabel.setContentHuggingPriority(.required, for: .vertical)
        accountTypeLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        accountTypeLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(NameSpace.accountTypeAvatarOffset)
            make.top.equalTo(nameLabel.snp.bottom).offset(NameSpace.accountTypeNameOffset)
            make.bottom.equalToSuperview().inset(NameSpace.accountTypeBottomInset)
            make.trailing.equalToSuperview().inset(NameSpace.accountTypeTrailingInset)
        }
    }
}

extension MoreScene.UserCell.ViewModel: UITableViewCellHeightProvider {
    
    private typealias NameSpace = MoreScene.UserCell
    
    func height(
        with tableViewWidth: CGFloat
    ) -> CGFloat {
        
        let avatarHeight: CGFloat = NameSpace.avatarTopInset
            + NameSpace.avatarSize.height
            + NameSpace.avatarBottomInset
        
        let nameWidth: CGFloat = tableViewWidth
            - NameSpace.avatarLeadingInset
            - NameSpace.avatarSize.width
            - NameSpace.nameAvatarOffset
            - NameSpace.nameTrailingInset
        let nameHeight: CGFloat = name.height(
            constraintedWidth: nameWidth,
            font: NameSpace.nameFont
        )
        
        let accountTypeWidth: CGFloat = tableViewWidth
            - NameSpace.avatarLeadingInset
            - NameSpace.avatarSize.width
            - NameSpace.accountTypeAvatarOffset
            - NameSpace.accountTypeTrailingInset
        let accountTypeHeight: CGFloat = name.height(
            constraintedWidth: accountTypeWidth,
            font: NameSpace.accountTypeFont
        )
        
        let textHeight: CGFloat = NameSpace.nameTopInset
            + nameHeight
            + NameSpace.accountTypeNameOffset
            + accountTypeHeight
            + NameSpace.accountTypeBottomInset
        
        return max(avatarHeight, textHeight)
    }
}
