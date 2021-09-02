import UIKit

final class AssetPickerView: UIView {
    
    private typealias NameSpace = AssetPickerView
    typealias OnSelectedPicker = () -> Void

    private static var iconSize: CGSize { .init(width: 14.0, height: 8.0) }
    
    private static var titleFont: UIFont { Theme.Fonts.regularFont.withSize(16.0) }
    private static var titleColor: UIColor { Theme.Colors.dark }
    private static var commonBackgroundColor: UIColor { Theme.Colors.mainBackgroundColor }

    // MARK: - Private properties

    private let titleLabel: UILabel = .init()
    private let iconView: UIImageView = .init()
        
    // MARK: - Public properties
    
    public var onSelectedPicker: OnSelectedPicker?
    
    public var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }
    
    public var iconImage: UIImage? {
        get { iconView.image }
        set { iconView.image = newValue?.withRenderingMode(.alwaysTemplate) }
    }
    
    // MARK: - Overridden
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
}

// MARK: - Private methods

private extension AssetPickerView {
    
    func commonInit() {
        setupView()
        setupTitleLabel()
        setupIconView()
        setupLayout()
    }
    
    func setupView() {
        backgroundColor = NameSpace.commonBackgroundColor
        
        let tapGesture: UITapGestureRecognizer = .init()
        tapGesture.cancelsTouchesInView = false
        tapGesture.addTarget(self, action: #selector(tapGestureAction))
        addGestureRecognizer(tapGesture)
    }
    
    @objc func tapGestureAction() {
        onSelectedPicker?()
    }
    
    func setupTitleLabel() {
        titleLabel.font = NameSpace.titleFont
        titleLabel.textColor = NameSpace.titleColor
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .center
        titleLabel.backgroundColor = NameSpace.commonBackgroundColor
    }
    
    func setupIconView() {
        iconView.layer.masksToBounds = true
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = Theme.Colors.dark
    }
    
    func setupLayout() {
        addSubview(titleLabel)
        addSubview(iconView)
        
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.snp.makeConstraints { (make) in
            make.top.leading.bottom.equalToSuperview().inset(5.0)
        }
        
        iconView.snp.makeConstraints { (make) in
            make.leading.equalTo(titleLabel.snp.trailing).offset(5.0)
            make.trailing.equalToSuperview().inset(5.0)
            make.centerY.equalToSuperview()
            make.size.equalTo(NameSpace.iconSize)
        }
    }
}
