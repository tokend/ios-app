import UIKit

class FeeAmountView: UIView {
    
    public struct ViewModel: Equatable {
        let title: String
        let value: String
    }
    
    private typealias NameSpace = FeeAmountView
        
    // MARK: - Private properties
    
    private let titleLabel: UILabel = .init()
    private let valueLabel: UILabel = .init()

    private static var titleLeadingInset: CGFloat { 0.0 }
    private static var labelsTopInset: CGFloat { 10.0 }
    private static var labelsBottomInset: CGFloat { 10.0 }
    private static var valueLeadingOffset: CGFloat { 16.0 }
    private static var valueTrailingInset: CGFloat { 24.0 }
    
    private static var titleFont: UIFont { Theme.Fonts.regularFont.withSize(13.0) }
    private static var titleTextColor: UIColor { Theme.Colors.dark }
    private static var valueFont: UIFont { Theme.Fonts.mediumFont.withSize(14.0) }
    private static var valueTextColor: UIColor { Theme.Colors.dark }
    private static var commonBackgroundColor: UIColor { Theme.Colors.white }
    
    // MARK: - Public properties

    public var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }
    
    public var value: String? {
        get { valueLabel.text }
        set { valueLabel.text = newValue }
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

private extension FeeAmountView {
    
    func commonInit() {
        setupView()
        setupTitleLabel()
        setupValueLabel()
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
    
    func setupValueLabel() {
        valueLabel.font = NameSpace.valueFont
        valueLabel.textColor = NameSpace.valueTextColor
        valueLabel.backgroundColor = NameSpace.commonBackgroundColor
        valueLabel.numberOfLines = 1
        valueLabel.lineBreakMode = .byWordWrapping
    }
    
    func setupLayout() {
        addSubview(titleLabel)
        addSubview(valueLabel)
        
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().inset(NameSpace.titleLeadingInset)
            make.centerY.equalTo(valueLabel)
        }
        
        valueLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(NameSpace.labelsTopInset)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(NameSpace.valueLeadingOffset)
            make.trailing.equalToSuperview().inset(NameSpace.valueTrailingInset)
            make.bottom.equalToSuperview().inset(NameSpace.labelsBottomInset)
        }
    }
}
