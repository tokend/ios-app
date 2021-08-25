import UIKit

extension BalanceDetailsScene {
    
    enum TransactionCell {
        
        private static var typeFont: UIFont { Theme.Fonts.mediumFont.withSize(15.0) }
        private static var amountFont: UIFont { Theme.Fonts.mediumFont.withSize(15.0) }
        private static var counterpartyFont: UIFont { Theme.Fonts.regularFont.withSize(15.0) }
        private static var dateFont: UIFont { Theme.Fonts.regularFont.withSize(15.0) }
        
        private static var iconSize: CGSize { .init(width: 45.0, height: 45.0) }
        private static var iconLeadingInset: CGFloat { 20.0 }
        private static var iconTopInset: CGFloat { 20.0 }
        private static var iconBottomInset: CGFloat { 20.0 }
        private static var typeIconOffset: CGFloat { 10.0 }
        private static var typeTopInset: CGFloat { 19.0 }
        private static var amountTypeOffset: CGFloat { 8.0 }
        private static var amountTopInset: CGFloat { 19.0 }
        private static var amountTrailingInset: CGFloat { 15.0 }
        private static var counterpartyIconOffset: CGFloat { 10.0 }
        private static var counterpartyTypeOffset: CGFloat { 7.0 }
        private static var counterpartyBottomInset: CGFloat { 22.0 }
        private static var dateCounterpartyOffset: CGFloat { 8.0 }
        private static var dateAmountOffset: CGFloat { 7.0 }
        private static var dateTrailingInset: CGFloat { 15.0 }
        private static var dateBottomInset: CGFloat { 22.0 }
        
        struct ViewModel: CellViewModel {
            
            let id: String
            let icon: TokenDUIImage
            let type: String
            let amount: String
            let amountColor: UIColor
            let counterparty: String?
            let date: String
            
            func setup(cell: View) {
                cell.icon = icon
                cell.type = type
                cell.amount = amount
                cell.amountColor = amountColor
                cell.counterparty = counterparty
                cell.date = date
            }
            
            var hashValue: Int {
                id.hash
            }
            
            func hash(
                into hasher: inout Hasher
            ) {
            
                hasher.combine(id)
            }
            
            public static func == (lhs: ViewModel, rhs: ViewModel) -> Bool {
                lhs.icon == rhs.icon
                    && lhs.type == rhs.type
                    && lhs.amount == rhs.amount
                    && lhs.amountColor == rhs.amountColor
                    && lhs.counterparty == rhs.counterparty
                    && lhs.date == rhs.date
            }
        }
        
        class View: UITableViewCell {
            
            // MARK: Private properties
            
            private let iconImageView: UIImageView = .init()
            private let typeLabel: UILabel = .init()
            private let amountLabel: UILabel = .init()
            private let counterpartyLabel: UILabel = .init()
            private let dateLabel: UILabel = .init()
            
            // MARK: Public properties
            
            public var icon: TokenDUIImage? {
                didSet {
                    iconImageView.setTokenDUIImage(icon)
                }
            }
            
            public var type: String? {
                get { typeLabel.text }
                set { typeLabel.text = newValue }
            }
            
            public var amount: String? {
                get { amountLabel.text }
                set { amountLabel.text = newValue }
            }
            
            public var amountColor: UIColor {
                get { amountLabel.textColor }
                set { amountLabel.textColor = newValue }
            }
            
            public var counterparty: String? {
                get { counterpartyLabel.text }
                set { counterpartyLabel.text = newValue }
            }
            
            public var date: String? {
                get { dateLabel.text }
                set { dateLabel.text = newValue }
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

private extension BalanceDetailsScene.TransactionCell.View {
    
    private typealias NameSpace = BalanceDetailsScene.TransactionCell
    
    func commonInit() {
        setupView()
        setupIconImageView()
        setupTypeLabel()
        setupAmountLabel()
        setupCounterpartyLabel()
        setupDateLabel()
        setupLayout()
    }
    
    func setupView() {
        selectionStyle = .none
        backgroundColor = .white
        contentView.backgroundColor = .white
        
        separatorInset.left = NameSpace.iconLeadingInset
            + NameSpace.iconSize.width
            + NameSpace.counterpartyIconOffset
    }
    
    func setupIconImageView() {
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.backgroundColor = .white
    }
    
    func setupTypeLabel() {
        typeLabel.font = NameSpace.typeFont
        typeLabel.textColor = .black
        typeLabel.numberOfLines = 1
        typeLabel.textAlignment = .left
        typeLabel.backgroundColor = .white
        typeLabel.lineBreakMode = .byWordWrapping
    }
    
    func setupAmountLabel() {
        amountLabel.font = NameSpace.amountFont
        amountLabel.textColor = .black
        amountLabel.numberOfLines = 1
        amountLabel.textAlignment = .right
        amountLabel.backgroundColor = .white
        amountLabel.lineBreakMode = .byWordWrapping
    }
    
    func setupCounterpartyLabel() {
        counterpartyLabel.font = NameSpace.counterpartyFont
        counterpartyLabel.textColor = .darkGray
        counterpartyLabel.numberOfLines = 1
        counterpartyLabel.textAlignment = .left
        counterpartyLabel.backgroundColor = .white
        counterpartyLabel.lineBreakMode = .byWordWrapping
    }
    
    func setupDateLabel() {
        dateLabel.font = NameSpace.dateFont
        dateLabel.textColor = .darkGray
        dateLabel.numberOfLines = 1
        dateLabel.textAlignment = .right
        dateLabel.backgroundColor = .white
        dateLabel.lineBreakMode = .byWordWrapping
    }
    
    func setupLayout() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(typeLabel)
        contentView.addSubview(amountLabel)
        contentView.addSubview(counterpartyLabel)
        contentView.addSubview(dateLabel)
        
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(NameSpace.iconLeadingInset)
            make.top.equalToSuperview().inset(NameSpace.iconTopInset)
            make.bottom.equalToSuperview().inset(NameSpace.iconBottomInset)
            make.size.equalTo(NameSpace.iconSize)
        }
        
        typeLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        typeLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(NameSpace.typeIconOffset)
            make.top.equalToSuperview().inset(NameSpace.typeTopInset)
        }
        
        amountLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        amountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        amountLabel.snp.makeConstraints { make in
            make.leading.equalTo(typeLabel.snp.trailing).offset(NameSpace.amountTypeOffset)
            make.top.equalToSuperview().inset(NameSpace.amountTopInset)
            make.trailing.equalToSuperview().inset(NameSpace.amountTrailingInset)
        }
        
        counterpartyLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        counterpartyLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        counterpartyLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(NameSpace.counterpartyIconOffset)
            make.top.equalTo(typeLabel.snp.bottom).offset(NameSpace.counterpartyTypeOffset)
            make.bottom.equalToSuperview().inset(NameSpace.counterpartyBottomInset)
        }
        
        dateLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        dateLabel.snp.makeConstraints { make in
            make.leading.equalTo(counterpartyLabel.snp.trailing).offset(NameSpace.dateCounterpartyOffset)
            make.top.equalTo(amountLabel.snp.bottom).offset(NameSpace.dateAmountOffset)
            make.trailing.equalToSuperview().inset(NameSpace.dateTrailingInset)
            make.bottom.equalToSuperview().inset(NameSpace.dateBottomInset)
        }
    }
}

extension BalanceDetailsScene.TransactionCell.ViewModel: UITableViewCellHeightProvider {
    
    private typealias NameSpace = BalanceDetailsScene.TransactionCell
    
    func height(
        with tableViewWidth: CGFloat
    ) -> CGFloat {
        
        let iconHeight: CGFloat = NameSpace.iconTopInset
            + NameSpace.iconSize.height
            + NameSpace.iconBottomInset
        
        let typeHeight: CGFloat = String.singleLineHeight(
            font: NameSpace.typeFont
        )
        let counterpartyHeight: CGFloat = String.singleLineHeight(
            font: NameSpace.counterpartyFont
        )
        let typeCounterpartyHeight: CGFloat = NameSpace.typeTopInset
            + typeHeight
            + NameSpace.counterpartyTypeOffset
            + counterpartyHeight
            + NameSpace.counterpartyBottomInset
        
        let amountHeight: CGFloat = String.singleLineHeight(
            font: NameSpace.amountFont
        )
        let dateHeight: CGFloat = String.singleLineHeight(
            font: NameSpace.dateFont
        )
        let amountDateHeight: CGFloat = NameSpace.amountTopInset
            + amountHeight
            + NameSpace.dateAmountOffset
            + dateHeight
            + NameSpace.dateBottomInset
         
        
        return max(iconHeight, typeCounterpartyHeight, amountDateHeight)
    }
}
