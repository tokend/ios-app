import UIKit

class TextFieldsContainer: UIView {
    
    // MARK: - Private properties
    
    private var separatorHeight: CGFloat { CGFloat(1.0).convertToPixels() }
    private var separatorSize: CGSize { .init(width: 16.0, height: separatorHeight) }
    private var separatorWidth: CGFloat { 116.0 }
    
    private var separatorColor: UIColor { Theme.Colors.white }
    private var commonBackgroundColor: UIColor { Theme.Colors.mainSeparatorColor }
    
    // MARK: - Public properties

    public var textFieldsList: [TextField] = [] {
        willSet {
            textFieldsList.forEach { $0.removeFromSuperview() }
            separatorsList.forEach { $0.removeFromSuperview() }
        }
        didSet {
            layoutTextFields()
        }
    }
    
    public var separatorsList: [UIView] = []
    
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

private extension TextFieldsContainer {
    
    func commonInit() {
        setupView()
    }
    
    func setupView() {
        backgroundColor = commonBackgroundColor
    }
    
    func layoutTextFields() {
        
        var previousField: TextField?
        separatorsList = []
        for field in textFieldsList {
            
            addSubview(field)
            
            if textFieldsList.indexOf(field) == 0 {
                field.snp.makeConstraints { (make) in
                    make.top.equalToSuperview().inset(separatorHeight)
                    make.leading.trailing.equalToSuperview()
                }
                addSeparatorView(for: field)
                previousField = field
            } else if textFieldsList.indexOf(field) == textFieldsList.count - 1 {
                if let previousField = previousField {
                    field.snp.makeConstraints { (make) in
                        make.top.equalTo(previousField.snp.bottom).offset(separatorHeight)
                        make.leading.trailing.equalToSuperview()
                        make.bottom.equalToSuperview().inset(separatorHeight)
                    }
                }
            } else {
                if let previousField = previousField {
                    field.snp.makeConstraints { (make) in
                        make.top.equalTo(previousField.snp.bottom).offset(separatorHeight)
                        make.leading.trailing.equalToSuperview()
                    }
                }
                addSeparatorView(for: field)
                previousField = field
            }
            
            previousField = field
        }
    }
    
    func addSeparatorView(for field: TextField) {
        let separator: UIView = .init()
        separator.backgroundColor = separatorColor
        separatorsList.append(separator)
        addSubview(separator)
        separator.snp.makeConstraints { (make) in
            make.top.equalTo(field.snp.bottom)
            make.leading.equalToSuperview()
            make.size.equalTo(separatorSize)
        }
    }
}
