import UIKit

enum CommonHeaderView {
    
    private static var titleTopInset: CGFloat { 32.0 }
    private static var titleLeadingInset: CGFloat { 18.0 }
    private static var titleTrailingInset: CGFloat { 18.0 }
    private static var titleBottomInset: CGFloat { 8.0 }
    
    private static var titleFont: UIFont { Theme.Fonts.regularFont.withSize(14.0) }
    private static var titleColor: UIColor { Theme.Colors.mainSeparatorColor }
    private static var commonBackgroundColor: UIColor { Theme.Colors.mainBackgroundColor }
    
    struct ViewModel: HeaderFooterViewModel {
        
        let id: String
        let title: String
        
        func setup(headerFooter: CommonHeaderView.View) {
            headerFooter.title = title
        }
        
        var hashValue: Int {
            id.hashValue
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        public static func == (lhs: ViewModel, rhs: ViewModel) -> Bool {
            
            return lhs.title == rhs.title
        }
    }
    
    class View: UITableViewHeaderFooterView {
        
        // MARK: - Private properties
        
        private let titleLabel: UILabel = .init()
        
        // MARK: - Public properties
        
        public var title: String? {
            get { titleLabel.text }
            set { titleLabel.text = newValue }
        }
        
        // MARK: - Overridden
        
        override init(reuseIdentifier: String?) {
            super.init(reuseIdentifier: reuseIdentifier)
            
            customInit()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            
            customInit()
        }
    }
}

// MARK: - Private methods

private extension CommonHeaderView.View {
    typealias NameSpace = CommonHeaderView

    func customInit() {
        setupView()
        setupTitleLabel()
        setupLayout()
    }
    
    func setupView() {
        backgroundView = UIView(frame: bounds)
        backgroundView?.backgroundColor = NameSpace.commonBackgroundColor
    }
    
    func setupTitleLabel() {
        titleLabel.font = NameSpace.titleFont
        titleLabel.textColor = NameSpace.titleColor
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .left
        titleLabel.backgroundColor = NameSpace.commonBackgroundColor
    }
    
    func setupLayout() {
        contentView.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(NameSpace.titleTopInset)
            make.leading.equalToSuperview().inset(NameSpace.titleLeadingInset)
            make.trailing.lessThanOrEqualToSuperview().inset(NameSpace.titleTrailingInset)
            make.bottom.equalToSuperview().inset(NameSpace.titleBottomInset)
        }
    }
}

extension CommonHeaderView.ViewModel: UITableViewHeaderFooterViewHeightProvider {
    typealias NameSpace = CommonHeaderView
    
    func height(with tableViewWidth: CGFloat) -> CGFloat {
        
        let availableWidth: CGFloat = tableViewWidth
            - NameSpace.titleLeadingInset
            - NameSpace.titleTrailingInset
        
        let titleTextHeight: CGFloat = title.height(
            constraintedWidth: availableWidth,
            font: NameSpace.titleFont
        )
        
        let height: CGFloat = NameSpace.titleTopInset
            + titleTextHeight
            + NameSpace.titleBottomInset
        
        return height
    }
}
