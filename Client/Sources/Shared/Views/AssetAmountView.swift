import UIKit

final class AssetAmountView: UIView {
    
    private typealias NameSpace = AssetAmountView
    typealias OnTextChanged = (String?) -> Void
    typealias OnReturnAction = () -> Void
    typealias OnSelectedPicker = () -> Void

    private static var commonBackgroundColor: UIColor { Theme.Colors.mainBackgroundColor }
    
    // MARK: - Private properties

    private let assetPickerView: AssetPickerView = .init()
    private let textField: UITextField = .init()
    
    private static var maximumCharactersCount: Int { 32 }
    
    // MARK: - Public properties
    
    public var onTextChanged: OnTextChanged?
    public var onReturnAction: OnReturnAction?
    public var onSelectedPicker: OnSelectedPicker?
    
    public var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }
    
    public var assetPickerTitle: String? {
        get { assetPickerView.title }
        set { assetPickerView.title = newValue }
    }
    
    public var assetPickerIcon: UIImage? {
        get { assetPickerView.iconImage }
        set { assetPickerView.iconImage = newValue }
    }
    
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
}

// MARK: - Private methods

private extension AssetAmountView {
    
    func commonInit() {
        setupView()
        setupTextField()
        setupAssetPickerView()
        setupLayout()
    }
    
    func setupView() {
        backgroundColor = NameSpace.commonBackgroundColor
    }
    
    func setupTextField() {
        textField.font = Theme.Fonts.regularFont.withSize(28.0)
        textField.textColor = Theme.Colors.dark
        textField.placeholderColor = Theme.Colors.grey
        textField.textAlignment = .right
        textField.keyboardType = .decimalPad
        textField.autocorrectionType = .no
        textField.backgroundColor = Theme.Colors.white
        textField.tintColor = Theme.Colors.dark
        textField.delegate = self
        textField.addTarget(
            self,
            action: #selector(textFieldDidChange),
            for: .editingChanged
        )
    }
    
    func setupAssetPickerView() {
        assetPickerView.onSelectedPicker = { [weak self] in
            self?.onSelectedPicker?()
        }
    }
    
    func setupLayout() {
        addSubview(textField)
        addSubview(assetPickerView)
        
        textField.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().inset(8.0)
            make.top.bottom.equalToSuperview().inset(5.0)
            make.width.greaterThanOrEqualTo(50.0)
            make.height.equalTo(40.0)
        }
        
        assetPickerView.snp.makeConstraints { (make) in
            make.leading.equalTo(textField.snp.trailing).offset(12.0)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(8.0)
        }
    }
}

// MARK: - UITextFieldDelegate

extension AssetAmountView: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(
        _ textField: UITextField
    ) -> Bool {
        return true
    }
    
    @objc public func textFieldDidChange() {
        onTextChanged?(text)
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
                
        return true
    }
}
