import UIKit

final class ActionButton: UIView {
    
    public typealias OnTouchUpInside = () -> Void

    static let height: CGFloat = 44.0
    
    // MARK: - Private properties
    
    private var separatorHeight: CGFloat { CGFloat(1.0).convertToPixels() }

    private let topSeparatorView: UIView = .init()
    private let button: UIButton = .init(type: .system)
    private let bottomSeparatorView: UIView = .init()
    
    // MARK: - Public properties

    public var title: String? {
        get { button.title(for: .normal) }
        set { button.setTitle(newValue, for: .normal) }
    }
    
    public var titleColor: UIColor = .systemBlue {
        didSet {
            button.setTitleColor(titleColor, for: .normal)
        }
    }
    
    public var isEnabled: Bool {
        get { button.isEnabled }
        set {
            button.isEnabled = newValue
        }
    }
    
    public var onTouchUpInside: OnTouchUpInside?

    // MARK: - Overridden

    public override init(frame: CGRect) {
        super.init(frame: frame)

        customInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        customInit()
    }
}

// MARK: - Private methods

private extension ActionButton {
    func customInit() {
        setupView()
        setupSeparators()
        setupButton()
        setupLayout()
    }

    func setupView() {
        backgroundColor = Theme.Colors.white
    }
    
    func setupSeparators() {
        topSeparatorView.backgroundColor = Theme.Colors.mainSeparatorColor
        bottomSeparatorView.backgroundColor = Theme.Colors.mainSeparatorColor
    }
    
    func setupButton() {
        button.backgroundColor = .clear
        button.titleLabel?.font = Theme.Fonts.regularFont.withSize(16.0)
        button.setTitleColor(.systemBlue, for: .normal)
        button.contentEdgeInsets = .init(top: 0.0, left: 16.0, bottom: 0.0, right: 16.0)
        button.contentHorizontalAlignment = .left

        button.addTarget(
            self,
            action: #selector(buttonTouchUpInside),
            for: .touchUpInside
        )
    }

    @objc func buttonTouchUpInside() {
        onTouchUpInside?()
    }

    func setupLayout() {
        addSubview(button)
        addSubview(topSeparatorView)
        addSubview(bottomSeparatorView)
    
        topSeparatorView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(separatorHeight)
        }
        
        button.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.height.equalTo(ActionButton.height)
        }
        
        bottomSeparatorView.snp.makeConstraints { (make) in
            make.bottom.leading.trailing.equalToSuperview()
            make.height.equalTo(separatorHeight)
        }
    }
}
