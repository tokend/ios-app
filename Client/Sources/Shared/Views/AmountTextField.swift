import UIKit

import UIKit

final class AmountTextField: UIView {
    
    struct Context: Equatable {
        let formatter: NumberFormatter

        static func ==(lhs: Context, rhs: Context) -> Bool {
            return lhs.formatter == rhs.formatter
        }
    }
    
    private typealias NameSpace = AmountTextField
    typealias OnAmountChanged = (AmountTextField) -> Void
    typealias OnShouldBeginEditing = () -> Bool
    typealias OnReturnAction = () -> Void
    
    private static var titleLeadingInset: CGFloat { 16.0 }
    private static var titleTrailingOffset: CGFloat { 16.0 }
    private static var textFieldTopInset: CGFloat { 13.0 }
    private static var textFieldLeadingInset: CGFloat { 116.0 }
    private static var imagesStackViewTopInset: CGFloat { 11.0 }
    private static var imagesStackViewLeadingOffset: CGFloat { 16.0 }
    private static var imagesStackViewTrailingInset: CGFloat { 16.0}
    private static var errorLabelTopOffset: CGFloat { 3.0 }
    private static var emptyErrorLabelTopOffset: CGFloat { 13.0 }
    private static var errorLeadingTrailingInset: CGFloat { 16.0 }
    private static var errorLabelBottomInset: CGFloat { 5.0 }
    
    private static var titleFont: UIFont { Theme.Fonts.regularFont.withSize(14.0) }
    private static var errorFont: UIFont { Theme.Fonts.mediumFont.withSize(10.0) }
    private static var commonBackgroundColor: UIColor { Theme.Colors.white }
    
    // MARK: - Private properties
    
    private let containerView: UIView = .init()
    private let gestureRecognizer: UITapGestureRecognizer = .init()
    private let titleLabel: UILabel = .init()
    private let textField: UITextField = .init()
    private let imagesStackView: UIStackView = .init()
    private let passwordImageView: UIImageView = .init()
    private let passwordImageViewGestureRecognizer: UITapGestureRecognizer = .init()
    private let errorLabel: UILabel = .init()
    
    private static var maximumCharactersCount: Int { 64 }
    
    private var isTextVisible: Bool = false {
        didSet {
            renderTextVisible()
        }
    }
    
    public var context: Context = Context(formatter: NumberFormatter()) {
        didSet {
            truncateAmountIfNeeded(
                textField.text ?? "",
                fromFormatter: oldValue.formatter,
                toFormatter: context.formatter)
            let newKeyboardType: UIKeyboardType
            if context.formatter.maximumFractionDigits <= 0 {
                newKeyboardType = .numberPad
            } else {
                newKeyboardType = .decimalPad
            }
            
            if textField.keyboardType != newKeyboardType {
                textField.keyboardType = newKeyboardType
                
                if textField.isFirstResponder {
                    textField.becomeFirstResponder()
                }
            }
        }
    }
    
    // MARK: - Public properties
    
    public static func textFieldHeight(with error: String? = nil) -> CGFloat {
        
        let titleHeight: CGFloat = String.singleLineHeight(font: titleFont)
        
        let errorHeight: CGFloat
        if error != nil {
            errorHeight = errorLabelTopOffset
                + String.singleLineHeight(font: errorFont)
        } else {
            errorHeight = emptyErrorLabelTopOffset
        }
        
        return textFieldTopInset
        + titleHeight
        + errorHeight
        + errorLabelBottomInset
    }

    public var onTextChanged: OnAmountChanged?
    public var onShouldBeginEditing: OnShouldBeginEditing?
    public var onReturnAction: OnReturnAction?
    
    private(set) var amount: Decimal?
    public weak var delegate: AmountTextFieldDelegate?
    
    public var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }
    
    public var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }
    
    public var placeholder: String? {
        get { textField.placeholder }
        set { textField.placeholder = newValue }
    }
    
    public var returnKeyType: UIReturnKeyType {
        get { textField.returnKeyType }
        set { textField.returnKeyType = newValue }
    }
    
    public var keyboardType: UIKeyboardType {
        get { textField.keyboardType }
        set { textField.keyboardType = newValue }
    }
    
    public var accessoryView: UIView? {
        get { textField.inputAccessoryView }
        set { textField.inputAccessoryView = newValue }
    }
    
    public var isSecureTextEntry: Bool = false {
        didSet {
            renderSecureTextEntry()
        }
    }
    
    public var capitalizationType: UITextAutocapitalizationType {
        get { textField.autocapitalizationType }
        set { textField.autocapitalizationType = newValue }
    }
    
    public var error: String? = nil {
        didSet {
            guard oldValue != error
            else {
                return
            }
            
            renderError()
        }
    }
    
    public var textFieldInputView: UIView? {
        get { textField.inputView }
        set { textField.inputView = newValue }
    }
    
    public var rightView: UIView? {
        get { textField.rightView }
        set { textField.rightView = newValue }
    }
    
    public var textFieldAutocorrectionType: UITextAutocorrectionType {
        get { textField.autocorrectionType }
        set { textField.autocorrectionType = newValue }
    }
    
    public var accessoryButton: UIButton? {
        didSet {
            if let accessoryButton = accessoryButton {
                accessoryButton.setContentHuggingPriority(.required, for: .horizontal)
                accessoryButton.setContentCompressionResistancePriority(.required, for: .horizontal)
                imagesStackView.addArrangedSubview(accessoryButton)
            }
        }
    }
    
    public var contentType: UITextContentType {
        get { textField.textContentType }
        set { textField.textContentType = newValue }
    }
    
    public var setUserInteractionEnabled: Bool {
        get { textField.isUserInteractionEnabled }
        set { textField.isUserInteractionEnabled = newValue }
    }
    
    public var textFieldTintColor: UIColor {
        get { textField.tintColor }
        set { textField.tintColor = newValue }
    }
    
    public var canPaste: Bool = true
    
    public var maxCharactersCount: Int = NameSpace.maximumCharactersCount
    
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
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.paste(_:)) {
            return canPaste
        }
        
        return super.canPerformAction(action, withSender: sender)
    }
    
    func setAmount(_ amount: Decimal) {
        setText(context.formatter.string(from: amount))
    }
    
    func setText(_ text: String?) {
        
        let newText = text ?? ""
        _ = self.textField(
            textField,
            shouldChangeCharactersIn: .init(
                location: 0,
                length: textField.text?.count ?? 0
            ),
            replacementString: newText
        )
    }
}

// MARK: - Private methods

private extension AmountTextField {
    
    func commonInit() {
        setupView()
        setupContainerView()
        setupTitleLabel()
        setupTextField()
        setupImagesStackView()
        setupPasswordImageView()
        setupErrorLabel()
        setupLayout()
    }
    
    func setupView() {
        backgroundColor = NameSpace.commonBackgroundColor
    }
    
    @objc func tapGestureAction() {
        becomeFirstResponder()
    }
    
    func setupContainerView() {
        backgroundColor = NameSpace.commonBackgroundColor
        gestureRecognizer.delegate = self
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.addTarget(self, action: #selector(tapGestureAction))
        containerView.addGestureRecognizer(gestureRecognizer)
    }
    
    func setupTitleLabel() {
        titleLabel.textColor = Theme.Colors.dark
        titleLabel.font = NameSpace.titleFont
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .left
        titleLabel.backgroundColor = .clear
        titleLabel.lineBreakMode = .byTruncatingTail
    }
    
    func setupTextField() {
        textField.textAlignment = .left
        textField.textColor = Theme.Colors.dark
        textField.placeholderColor = Theme.Colors.grey
        textField.font = Theme.Fonts.regularFont.withSize(14.0)
        textField.autocorrectionType = .no
        textField.backgroundColor = Theme.Colors.white
        textField.tintColor = Theme.Colors.dark
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    func setupImagesStackView() {
        imagesStackView.axis = .horizontal
        imagesStackView.spacing = 5.0
        imagesStackView.alignment = .fill
        imagesStackView.distribution = .fillEqually
    }
    
    func setupPasswordImageView() {
        passwordImageView.backgroundColor = Theme.Colors.white
        passwordImageView.contentMode = .scaleAspectFit
        passwordImageView.isUserInteractionEnabled = true
        passwordImageView.isHidden = true
        
        passwordImageViewGestureRecognizer.addTarget(
            self,
            action: #selector(passwordImageViewTouchUpInside)
        )
        passwordImageView.addGestureRecognizer(passwordImageViewGestureRecognizer)
    }
    
    @objc func passwordImageViewTouchUpInside(sender: UIImageView) {
        isTextVisible = !isTextVisible
    }
    
    func setupErrorLabel() {
        errorLabel.textColor = Theme.Colors.errorColor
        errorLabel.font = NameSpace.errorFont
        errorLabel.numberOfLines = 1
        errorLabel.textAlignment = .left
        errorLabel.backgroundColor = .clear
        errorLabel.lineBreakMode = .byTruncatingTail
    }
    
    func setupLayout() {
        addSubview(containerView)
        addSubview(titleLabel)
        addSubview(textField)
        addSubview(imagesStackView)
        imagesStackView.addArrangedSubview(passwordImageView)
        addSubview(errorLabel)
        
        containerView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(NameSpace.textFieldTopInset)
            make.leading.equalToSuperview().inset(NameSpace.titleLeadingInset)
            make.trailing.lessThanOrEqualTo(textField.snp.leading).offset(-NameSpace.titleTrailingOffset)
        }
        
        textField.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(NameSpace.textFieldTopInset)
            make.leading.equalToSuperview().inset(NameSpace.textFieldLeadingInset)
        }
        
        passwordImageView.setContentHuggingPriority(.required, for: .horizontal)
        passwordImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imagesStackView.setContentHuggingPriority(.required, for: .horizontal)
        imagesStackView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imagesStackView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(NameSpace.imagesStackViewTopInset)
            make.leading.equalTo(textField.snp.trailing).offset(NameSpace.imagesStackViewLeadingOffset)
            make.trailing.equalToSuperview().inset(NameSpace.imagesStackViewTrailingInset)
            make.height.equalTo(20.0)
        }
        
        errorLabel.setContentHuggingPriority(.required, for: .horizontal)
        errorLabel.setContentHuggingPriority(.required, for: .vertical)
        errorLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        errorLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        remakeErrorLabelConstraints()
    }
    
    func renderSecureTextEntry() {
        textField.isSecureTextEntry = isSecureTextEntry
        passwordImageView.isHidden = !isSecureTextEntry
        passwordImageView.image = Assets.password_is_hidden_icon.image
    }
    
    func renderTextVisible() {
        if isTextVisible {
            passwordImageView.image = Assets.password_is_visible_icon.image
        } else {
            passwordImageView.image = Assets.password_is_hidden_icon.image
        }
        textField.isSecureTextEntry = !isTextVisible
    }
    
    func renderError() {
        errorLabel.text = error
        remakeErrorLabelConstraints()
    }
    
    func remakeErrorLabelConstraints() {
        errorLabel.snp.remakeConstraints { (remake) in
            remake.leading.trailing.equalToSuperview().inset(NameSpace.errorLeadingTrailingInset)
            
            if error == nil {
                remake.top.equalTo(titleLabel.snp.bottom).offset(NameSpace.emptyErrorLabelTopOffset)
                remake.top.equalTo(textField.snp.bottom).offset(NameSpace.emptyErrorLabelTopOffset)
                remake.top.equalTo(imagesStackView.snp.bottom).offset(NameSpace.emptyErrorLabelTopOffset)
                remake.height.equalTo(0.0)
                remake.bottom.equalToSuperview()
            } else {
                remake.top.equalTo(titleLabel.snp.bottom).offset(NameSpace.errorLabelTopOffset)
                remake.top.equalTo(textField.snp.bottom).offset(NameSpace.errorLabelTopOffset)
                remake.top.equalTo(imagesStackView.snp.bottom).offset(NameSpace.errorLabelTopOffset)
                remake.bottom.equalToSuperview().inset(NameSpace.errorLabelBottomInset)
            }
        }
    }
}

// MARK: - UITextFieldDelegate

extension AmountTextField: UITextFieldDelegate {

    func textFieldShouldBeginEditing(
        _ textField: UITextField
    ) -> Bool {
        onShouldBeginEditing?() ?? true
    }
    
    @objc public func textFieldDidChange() {
        onTextChanged?(self)
    }
    
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
//
//        if string == "\n" {
//            onReturnAction?()
//            return false
//        }
        if delegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: string) == false {
            return false
        }
        
        let newText = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        if let newString = checkEnteredAmount(newText, withFormatter: context.formatter) {
            setText(newString)
            amount = context.formatter.decimal(from: newString)
            delegate?.amountTextFieldDidEditAmount?(self)
            onTextChanged?(self)
        }
        
        return false
    }
    
    private func checkEnteredAmount(_ amountString: String, withFormatter formatter: NumberFormatter) -> String? {
        var amountString = amountString
        if amountString.count == 0 {
            return amountString
        }
        
        guard formatter.decimal(from: amountString) != nil
            else {
                return nil
        }
        
        let keyboardDecimalSeparator = NumberFormatter().decimalSeparator ?? Locale.current.decimalSeparator ?? "."
        var components = amountString.components(separatedBy: keyboardDecimalSeparator)
        
        if components.count > 2 {
            return nil
        }
        
        if components.count == 2 {
            if formatter.maximumFractionDigits == 0 {
                return nil
            }
            
            if components[1].count > formatter.maximumFractionDigits {
                return nil
            }
        }
        
        if components[0].count > formatter.maximumIntegerDigits {
            return nil
        }
        
        while amountString.starts(with: "0") {
            amountString.removeFirst()
        }
        
        components = amountString.components(separatedBy: keyboardDecimalSeparator)
        
        if components[0].isEmpty {
            amountString.insert("0", at: amountString.startIndex)
            components = amountString.components(separatedBy: keyboardDecimalSeparator)
        }
        
        return amountString
    }
    
    private func truncateAmountIfNeeded(
        _ amountString: String,
        fromFormatter: NumberFormatter,
        toFormatter: NumberFormatter
    ) {
        
        if fromFormatter.maximumFractionDigits > toFormatter.maximumFractionDigits {
            if let amountDecimal = toFormatter.decimal(from: amountString),
                let string = toFormatter.string(from: amountDecimal) {
                setText(string)
                return
            }
        }
        setText(amountString)
    }
}

extension AmountTextField: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        
        return gestureRecognizer == gestureRecognizer
            && otherGestureRecognizer == passwordImageViewGestureRecognizer
    }
}

@objc protocol AmountTextFieldDelegate: UITextFieldDelegate {
    @objc optional func amountTextFieldDidEditAmount(_ textfield: AmountTextField)
}
