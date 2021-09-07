import UIKit

class FeesStackView: UIView {
    
    struct ViewModel {
        let items: [UIView]
        let isLoading: Bool
    }
    
    private typealias NameSpace = FeesStackView
        
    // MARK: - Private properties

    private let stackView: UIStackView = .init()
    private let activityIndicator: UIActivityIndicatorView = .init()

    private static var stackViewInsets: UIEdgeInsets { .init(top: 0.0, left: 16.0, bottom: 0.0, right: 0.0) }
    private static var separatorHeight: CGFloat { CGFloat(1.0).convertToPixels() }
    private static var separatorColor: UIColor { Theme.Colors.mainSeparatorColor }

    private static var commonBackgroundColor: UIColor { Theme.Colors.white }
    
    // MARK: - Public properties

    public var stackViewItems: [UIView] = [] {
        didSet {
            renderStackViewTabs()
        }
    }
    
    public var isLoading: Bool = false {
        didSet {
            renderLoadingStatus()
        }
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

private extension FeesStackView {
    
    func commonInit() {
        setupView()
        setupStackView()
        setupActivityIndicatorView()
        setupLayout()
    }
    
    func setupView() {
        backgroundColor = NameSpace.commonBackgroundColor
    }
    
    func setupStackView() {
        stackView.axis = .vertical
        stackView.spacing = 0.0
        stackView.alignment = .fill
        stackView.distribution = .fill
    }
    
    func setupActivityIndicatorView() {
        activityIndicator.style = .gray
        activityIndicator.color = .systemGray
    }
    
    func setupLayout() {
        addSubview(activityIndicator)
        addSubview(stackView)
        
        activityIndicator.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 20.0, height: 20.0))
        }
        
        stackView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(NameSpace.stackViewInsets)
        }
    }
    
    func renderStackViewTabs() {
        stackView.removeArrangedSubviews()
        
        for (index, view) in stackViewItems.enumerated() {
            stackView.addArrangedSubview(view)
            
            if index < stackViewItems.count - 1 {
                stackView.addArrangedSubview(createSeparatorView())
            }
        }
    }
    
    func renderLoadingStatus() {
        
        if isLoading {
            stackView.isHidden = true
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
        } else {
            stackView.isHidden = false
            activityIndicator.isHidden = true
            activityIndicator.startAnimating()
        }
    }
    
    func createSeparatorView() -> UIView {
        
        let view: UIView = .init()
        view.backgroundColor = NameSpace.separatorColor
        
        view.snp.makeConstraints { (make) in
            make.height.equalTo(NameSpace.separatorHeight)
        }
        
        return view
    }
}
