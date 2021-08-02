import UIKit

extension SettingsScene {
    enum SwitcherCell {
        
        private static var switcherSize: CGSize { .init(width: 52.0, height: 32.0) }
        private static var iconSize: CGSize { .init(width: 23.0, height: 23.0) }
        private static var iconLeadingInset: CGFloat { 18.0 }
        private static var iconTopInset: CGFloat { 8.0 }
        private static var iconBottomInset: CGFloat { 8.0 }
        private static var titleTopInset: CGFloat { 10.0 }
        private static var titleLeadingOffset: CGFloat { 18.0 }
        private static var titleBottomInset: CGFloat { 10.0 }
        private static var switcherTopInset: CGFloat { 3.0 }
        private static var switcherTrailingInset: CGFloat { 20.0 }
        private static var switcherBottomInset: CGFloat { 3.0 }
        private static var titleSwitcherOffset: CGFloat { 16.0 }
        private static var containerLeadingTrailingInset: CGFloat { 24.0 }

        private static var titleColor: UIColor { Theme.Colors.dark }
        private static var titleFont: UIFont { Theme.Fonts.regularFont.withSize(16.0) }
        private static var cellBackgroundColor: UIColor { Theme.Colors.white }
        private static var containerBackgroundColor: UIColor { Theme.Colors.white }
        
        struct ViewModel: CellViewModel {
            let id: String
            let icon: TokenDUIImage
            let title: String
            var switcherStatus: Bool
            
            func setup(cell: View) {
                cell.icon = icon
                cell.title = title
                cell.value = switcherStatus
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
                    && lhs.switcherStatus == rhs.switcherStatus
            }
        }
        
        class View: UITableViewCell {
            
            typealias OnSwitched = (Bool) -> Void
            
            // MARK: - Private properties
            
            private let iconView: UIImageView = .init()
            private let titleLabel: UILabel = .init()
            private let switcher: UISwitch = .init()
            
            // MARK: - Public Properties
            
            public var onSwitched: OnSwitched?
            
            public var icon: TokenDUIImage? {
                didSet {
                    iconView.setTokenDUIImage(icon)
                }
            }
            
            public var title: String? {
                get { titleLabel.text }
                set { titleLabel.text = newValue }
            }
            
            public var value: Bool {
                get { switcher.isOn }
                set { switcher.isOn = newValue }
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

private extension SettingsScene.SwitcherCell.View {
    typealias NameSpace = SettingsScene.SwitcherCell
    
    func commonInit() {
        setupView()
        setupIconImageView()
        setupTitleLabel()
        setupSwitcher()
        setupLayout()
    }
    
    func setupView() {
        backgroundColor = NameSpace.cellBackgroundColor
        selectionStyle = .none
        separatorInset.left = NameSpace.iconLeadingInset
            + NameSpace.iconSize.width
            + NameSpace.titleLeadingOffset
    }
    
    func setupIconImageView() {
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .lightGray
        iconView.backgroundColor = Theme.Colors.white
    }
    
    func setupTitleLabel() {
        titleLabel.font = NameSpace.titleFont
        titleLabel.textColor = NameSpace.titleColor
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .left
        titleLabel.backgroundColor = NameSpace.containerBackgroundColor
        titleLabel.lineBreakMode = .byWordWrapping
    }
    
    func setupSwitcher() {
        switcher.tintColor = Theme.Colors.switchOffTintColor
        switcher.onTintColor = Theme.Colors.switchOnTintColor
        switcher.addTarget(
            self,
            action: #selector(switcherValueChanged),
            for: .valueChanged
        )
    }
    
    @objc func switcherValueChanged() {
        onSwitched?(switcher.isOn)
    }
    
    func setupLayout() {
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(switcher)
        
        iconView.snp.makeConstraints { (make) in
            make.size.equalTo(NameSpace.iconSize)
            make.leading.equalToSuperview().inset(NameSpace.iconLeadingInset)
            make.top.greaterThanOrEqualToSuperview().inset(NameSpace.iconTopInset)
            make.bottom.lessThanOrEqualToSuperview().inset(NameSpace.iconBottomInset)
            make.centerY.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.greaterThanOrEqualToSuperview().inset(NameSpace.titleTopInset)
            make.leading.equalTo(iconView.snp.trailing).offset(NameSpace.titleLeadingOffset)
            make.bottom.lessThanOrEqualToSuperview().inset(NameSpace.titleBottomInset)
            make.centerY.equalToSuperview()
        }
        
        switcher.snp.makeConstraints { (make) in
            make.top.greaterThanOrEqualToSuperview().inset(NameSpace.switcherTopInset)
            make.leading.equalTo(titleLabel.snp.trailing).offset(NameSpace.titleSwitcherOffset)
            make.trailing.equalToSuperview().inset(NameSpace.switcherTrailingInset)
            make.bottom.lessThanOrEqualToSuperview().inset(NameSpace.switcherBottomInset)
            make.size.equalTo(NameSpace.switcherSize)
            make.centerY.equalToSuperview()
        }
    }
}

extension SettingsScene.SwitcherCell.ViewModel: UITableViewCellHeightProvider {
    typealias NameSpace = SettingsScene.SwitcherCell
    func height(with tableViewWidth: CGFloat) -> CGFloat {
        
        let width: CGFloat = tableViewWidth -
            NameSpace.iconLeadingInset
                - NameSpace.iconSize.width
                - NameSpace.titleLeadingOffset
                - NameSpace.titleSwitcherOffset
                - NameSpace.switcherTrailingInset
                - NameSpace.switcherSize.width
        
        let titleTextHeight: CGFloat = title.height(
            constraintedWidth: width,
            font: NameSpace.titleFont
        )
        
        let cellSwitcherHeight: CGFloat = NameSpace.switcherTopInset
            + NameSpace.switcherSize.height
            + NameSpace.switcherBottomInset
        
        let cellTitleHeight: CGFloat = NameSpace.titleTopInset
            + titleTextHeight
            + NameSpace.titleBottomInset
        
        return max(cellSwitcherHeight, cellTitleHeight)
    }
}
