import UIKit

final class TextField: UIView {
    
    private typealias NameSpace = TextField
    typealias OnTextChanged = (String?) -> Void
    typealias OnReturnAction = () -> Void
    
    private static var titleLeadingInset: CGFloat { 16.0 }
    private static var textFieldTopBottomInset: CGFloat { 11.0 }
    private static var textFieldLeadingOffset: CGFloat { 16.0 }
    private static var imagesStackViewTopBottomInset: CGFloat { 5.0 }
    private static var imagesStackViewLeadingOffset: CGFloat { 16.0 }
    private static var imagesStackViewTrailingInset: CGFloat { 16.0 }
    
    private static var commonBackgroundColor: UIColor { Theme.Colors.white }
    
    // MARK: - Private properties
    
    private let gestureRecognizer: UITapGestureRecognizer = .init()
    private let titleLabel: UILabel = .init()
    private let textField: UITextField = .init()
    private let imagesStackView: UIStackView = .init()
    private let passwordImageView: UIImageView = .init()
    private let passwordImageViewGestureRecognizer: UITapGestureRecognizer = .init()

    private static var maximumCharactersCount: Int { 64 }
    
    private var isTextVisible: Bool = false {
        didSet {
            renderTextVisible()
        }
    }
    
    // MARK: - Public properties

    public var onTextChanged: OnTextChanged?
    public var onReturnAction: OnReturnAction?
    
    public var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }
    
    public var text: String? {
        get { textField.text }
        set {
            textField.text = newValue
//            renderTextFieldState()
        }
    }
    
    public var placeholder: String? {
        get { textField.placeholder }
        set {
            textField.placeholder = newValue
//            renderTextFieldState()
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
//            renderTextFieldState()
        }
    }
    
    public var textFieldInputView: UIView? {
        get { textField.inputView }
        set { textField.inputView = newValue }
    }
    
    public var textFieldAutocorrectionType: UITextAutocorrectionType {
        get { textField.autocorrectionType }
        set { textField.autocorrectionType = newValue }
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
}

// MARK: - Private methods

private extension TextField {
    
    func commonInit() {
        setupView()
        setupTitleLabel
        setupTextField
        setupImagesStackView
    }
    
    func setupView() {
        backgroundColor = NameSpace.commonBackgroundColor
        
        gestureRecognizer.delegate = self
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.addTarget(self, action: #selector(tapGestureAction))
        addGestureRecognizer(gestureRecognizer)
    }
    
    @objc func tapGestureAction() {
        becomeFirstResponder()
    }
    
    func setupTitleLabel() {
        titleLabel.textColor = Theme.Colors.dark
        titleLabel.font = Theme.Fonts.regularFont.withSize(14.0)
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
    
    func setupLayout() {
        addSubview(titleLabel)
        addSubview(textField)
        addSubview(imagesStackView)
        imagesStackView.addSubview(passwordImageView)
        
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(NameSpace.textFieldTopBottomInset)
            make.leading.equalToSuperview().inset(NameSpace.titleLeadingInset)
            make.trailing.lessThanOrEqualToSuperview().multipliedBy(0.4)
        }
        
        textField.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(NameSpace.textFieldTopBottomInset)
            make.leading.equalTo(titleLabel.snp.trailing).offset(NameSpace.textFieldLeadingOffset)
        }
        
        passwordImageView.setContentHuggingPriority(.required, for: .horizontal)
        passwordImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imagesStackView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(NameSpace.imagesStackViewTopBottomInset)
            make.leading.equalTo(textField.snp.trailing).offset(NameSpace.textFieldLeadingOffset)
            make.trailing.equalToSuperview().inset(NameSpace.imagesStackViewTrailingInset)
        }
    }
    
    func renderSecureTextEntry() {
        textField.isSecureTextEntry = isSecureTextEntry
        passwordImageView.isHidden = !isSecureTextEntry
//        passwordImageView.image = Assets.passwordIsHidden.image
    }
    
    func renderTextVisible() {
        if isTextVisible {
//            passwordImageView.image = Assets.passwordIsVisible.image
        } else {
//            passwordImageView.image = Assets.passwordIsHidden.image
        }
        textField.isSecureTextEntry = !isTextVisible
    }
}

// MARK: - UITextFieldDelegate

extension TextField: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
//        renderTextFieldState()
    }
    
    @objc public func textFieldDidChange() {
        onTextChanged?(text)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
//        renderTextFieldState()
    }
    
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
                
        if string == "\n" {
            onReturnAction?()
            return false
        }
        
        let newText = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        
        guard newText.count <= maxCharactersCount
            else {
                return false
        }
        
//        renderTextFieldState()
        
        return true
    }
}

extension TextField: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        
        return gestureRecognizer == gestureRecognizer
            && otherGestureRecognizer == passwordImageViewGestureRecognizer
    }
}
