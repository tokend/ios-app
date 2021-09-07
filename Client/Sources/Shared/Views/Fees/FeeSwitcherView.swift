import UIKit

class FeeSwitcherView: UIView {
    
    public struct ViewModel: Equatable {
        let title: String
        let switcherValue: Bool
    }
    
    private typealias NameSpace = FeeSwitcherView
    typealias OnSwitched = (Bool) -> Void
    
    // MARK: - Private properties
    
    private let titleLabel: UILabel = .init()
    private let switcher: UISwitch = .init()
    
    private static var titleTopBottomInset: CGFloat { 15.0 }
    private static var titleLeadingInset: CGFloat { 0.0 }
    private static var switcherLeadingOffset: CGFloat { 16.0 }
    private static var switcherTrailingInset: CGFloat { 24.0 }
    private static var switcherSize: CGSize { .init(width: 52.0, height: 32.0) }
    
    private static var titleFont: UIFont { Theme.Fonts.regularFont.withSize(14.0) }
    private static var titleTextColor: UIColor { Theme.Colors.dark }
    private static var commonBackgroundColor: UIColor { Theme.Colors.white }

    // MARK: - Public Properties
    
    public var onSwitched: OnSwitched?
    
    public var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }
    
    public var value: Bool {
        get { switcher.isOn }
        set { switcher.isOn = newValue }
    }
    
    // MARK: - Overridden

    override init(frame: CGRect) {
        super.init(frame: frame)

        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        commonInit()
    }
}

// MARK: - Private methods

private extension FeeSwitcherView {
    
    func commonInit() {
        setupView()
        setupTitleLabel()
        setupSwitcher()
        setupLayout()
    }
    
    func setupView() {
        backgroundColor = NameSpace.commonBackgroundColor
    }
    
    func setupTitleLabel() {
        titleLabel.font = NameSpace.titleFont
        titleLabel.textColor = NameSpace.titleTextColor
        titleLabel.backgroundColor = NameSpace.commonBackgroundColor
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byWordWrapping
    }
    
    func setupSwitcher() {
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
        addSubview(titleLabel)
        addSubview(switcher)
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(NameSpace.titleTopBottomInset)
            make.leading.equalToSuperview().inset(NameSpace.titleLeadingInset)
        }
        
        switcher.snp.makeConstraints { (make) in
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(NameSpace.switcherLeadingOffset)
            make.trailing.equalToSuperview().inset(NameSpace.switcherTrailingInset)
            make.size.equalTo(NameSpace.switcherSize)
            make.centerY.equalTo(titleLabel)
        }
    }
}
