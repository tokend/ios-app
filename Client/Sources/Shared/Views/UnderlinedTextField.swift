import UIKit

final class UnderlinedTextField: UIView {

    private typealias NameSpace = UnderlinedTextField
    typealias OnTextChanged = (String?) -> Void
    typealias OnReturnAction = () -> Void

    private static var titleFont: UIFont { Theme.Fonts.regularFont.withSize(14.0) }
    private static var textFieldInset: CGFloat { 8.0 }
    private static var textFieldUnderlineOffset: CGFloat { 15.0 }

    // MARK: - Private properties

    private let textField: UITextField = .init()
    private let underline: UnderlineView = .init()

    private var commonBackgroundColor: UIColor { Theme.Colors.mainBackgroundColor }

    // MARK: - Public properties

    public var onTextChanged: OnTextChanged?
    public var onReturnAction: OnReturnAction?

    public var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }
    
    public var rightView: UIView? {
        get { textField.rightView }
        set { textField.rightView = newValue }
    }

    public var rightViewMode: UITextField.ViewMode {
        get { textField.rightViewMode }
        set { textField.rightViewMode = newValue }
    }

    public var placeholder: String? {
        get {
            textField.placeholder
        }
        set {
            textField.placeholder = newValue
        }
    }

    public var returnKeyType: UIReturnKeyType {
        get { textField.returnKeyType }
        set { textField.returnKeyType = newValue }
    }

    public var keyboardType: UIKeyboardType {
        get { textField.keyboardType }
        set { textField.keyboardType = newValue }
    }

    public var textAlignment: NSTextAlignment {
        get { textField.textAlignment }
        set {
            textField.textAlignment = newValue
        }
    }

    public var clearButtonMode: UITextField.ViewMode {
        get { textField.clearButtonMode }
        set { textField.clearButtonMode = newValue }
    }

    public var accessoryView: UIView? {
        get { textField.inputAccessoryView }
        set { textField.inputAccessoryView = newValue }
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

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
    }

    @discardableResult
    override func resignFirstResponder() -> Bool {
        textField.resignFirstResponder()
    }

    override var isFirstResponder: Bool {
        textField.isFirstResponder
    }
}

// MARK: - Private methods

private extension UnderlinedTextField {

    func commonInit() {
        setupView()
        setupTextField()
        setupUnderline()
        setupLayout()
    }

    func setupView() {
        backgroundColor = commonBackgroundColor

        let tapGesture: UITapGestureRecognizer = .init()
        tapGesture.cancelsTouchesInView = false
        tapGesture.addTarget(self, action: #selector(tapGestureAction))
        addGestureRecognizer(tapGesture)
    }

    @objc func tapGestureAction() {
        becomeFirstResponder()
    }

    func setupTextField() {

        textField.delegate = self
        textField.textAlignment = .left
        textField.textColor = Theme.Colors.dark
        textField.font = Theme.Fonts.mediumFont.withSize(14.0)
        textField.autocorrectionType = .no
        textField.backgroundColor = commonBackgroundColor
        textField.tintColor = Theme.Colors.textFieldTintColor
        textField.placeholderColor = Theme.Colors.textFieldPlaceholderColor
        textField.backgroundColor = commonBackgroundColor

        if #available(iOS 13.0, *) {
            textField.overrideUserInterfaceStyle = .light
        }

        textField.addTarget(
            self,
            action: #selector(textFieldEditingChanged),
            for: .editingChanged
        )
    }

    @objc func textFieldEditingChanged() {
        onTextChanged?(textField.text)
    }

    func setupUnderline() { }

    func setupLayout() {
        addSubview(textField)
        addSubview(underline)

        textField.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        textField.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().inset(NameSpace.textFieldInset)
        }

        underline.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(textField.snp.bottom).offset(NameSpace.textFieldUnderlineOffset)
        }
    }
}

extension UnderlinedTextField: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
                
        if string == "\n" {
            onReturnAction?()
            return false
        }
                
        return true
    }
}
