import UIKit

final class ActionButton: UIView {
    
    public typealias OnTouchUpInside = () -> Void

    static let height: CGFloat = 40.0

    // MARK: - Private properties

    private let topSeparatorView: UIView = .init()
    private let button: UIButton = .init()
    private let bottomSeparatorView: UIView = .init()
    
    // MARK: - Public properties

    public var title: String? {
        get { button.title(for: .normal) }
        set { button.setTitle(newValue, for: .normal) }
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
        addSubview(topSeparatorView)
        addSubview(button)
        addSubview(bottomSeparatorView)
    
        topSeparatorView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(1.0)
        }
        
        button.snp.makeConstraints { (make) in
            make.top.equalTo(topSeparatorView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(ActionButton.height - 2.0)
        }
        
        bottomSeparatorView.snp.makeConstraints { (make) in
            make.top.equalTo(button.snp.bottom)
            make.bottom.leading.trailing.equalToSuperview()
            make.height.equalTo(1.0)
        }
    }
}
