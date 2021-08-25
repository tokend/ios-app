import UIKit

extension DashboardScene {
    enum HeaderView {
        
        private static var titleTopInset: CGFloat { 16.0 }
        private static var titleLeadingInset: CGFloat { 18.0 }
        private static var titleTrailingInset: CGFloat { 18.0 }
        private static var titleBottomInset: CGFloat { 16.0 }
        
        private static var titleFont: UIFont { Theme.Fonts.semiboldFont.withSize(22.0) }
        private static var titleColor: UIColor { Theme.Colors.dark }
        private static var commonBackgroundColor: UIColor { Theme.Colors.mainBackgroundColor }
        
        struct ViewModel: HeaderFooterViewModel {
            
            let id: String
            let title: String
            
            func setup(headerFooter: DashboardScene.HeaderView.View) {
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
}

// MARK: - Private methods

private extension DashboardScene.HeaderView.View {
    typealias NameSpace = DashboardScene.HeaderView
    
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
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .center
        titleLabel.backgroundColor = NameSpace.commonBackgroundColor
    }
    
    func setupLayout() {
        contentView.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(NameSpace.titleTopInset)
            make.leading.greaterThanOrEqualToSuperview().inset(NameSpace.titleLeadingInset)
            make.trailing.lessThanOrEqualToSuperview().inset(NameSpace.titleTrailingInset)
            make.bottom.equalToSuperview().inset(NameSpace.titleBottomInset).priority(999.0)
            make.centerX.equalToSuperview()
        }
    }
}

extension DashboardScene.HeaderView.ViewModel: UITableViewHeaderFooterViewHeightProvider {
    typealias NameSpace = DashboardScene.HeaderView

    func height(with tableViewWidth: CGFloat) -> CGFloat {
        
        let titleTextHeight: CGFloat = String.singleLineHeight(font: NameSpace.titleFont)
        
        let height: CGFloat = NameSpace.titleTopInset
            + titleTextHeight
            + NameSpace.titleBottomInset
        
        return height
    }
}
