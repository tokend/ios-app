import UIKit
import RxCocoa
import RxSwift

class TextFieldView: UIView {
    
    // MARK: - Public properties
    
    var text: String? {
        get { return self.textField.text }
        set { self.textField.text = newValue }
    }
    
    var placeholder: String? {
        get { return self.textField.placeholder }
        set { self.textField.placeholder = newValue }
    }
    
    var attributedPlaceholder: NSAttributedString? {
        get { return self.textField.attributedPlaceholder }
        set { self.textField.attributedPlaceholder = newValue }
    }
    
    var textColor: UIColor? {
        didSet {
            self.updateTextColor()
        }
    }
    
    var invalidTextColor: UIColor? {
        didSet {
            self.updateTextColor()
        }
    }
    
    var textAlignment: NSTextAlignment {
        get { return self.textField.textAlignment }
        set { self.textField.textAlignment = newValue }
    }
    
    var font: UIFont? {
        get { return self.textField.font }
        set { self.textField.font = newValue }
    }
    
    var keyboardType: UIKeyboardType {
        get { return self.textField.keyboardType }
        set { self.textField.keyboardType = newValue }
    }
    
    var autocapitalizationType: UITextAutocapitalizationType {
        get { return self.textField.autocapitalizationType }
        set { self.textField.autocapitalizationType = newValue }
    }
    
    var autocorrectionType: UITextAutocorrectionType {
        get { return self.textField.autocorrectionType }
        set { self.textField.autocorrectionType = newValue }
    }
    
    var isSecureTextEntry: Bool {
        get { return self.textField.isSecureTextEntry }
        set { self.textField.isSecureTextEntry = newValue }
    }
    
    var isValid: Bool = true {
        didSet {
            self.updateTextColor()
        }
    }
    
    var onShouldReturn: ((_ textFieldView: TextFieldView) -> Bool) = { _ in return true }
    
    // MARK: - Private properties
    
    private let textField: UITextField = UITextField()
    
    private var onShouldReplace: ((_ currentText: String, _ range: NSRange, _ replacementString: String) -> Bool)?
    
    // MARK: -
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.customInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.customInit()
    }
    
    private func customInit() {
        self.setupView()
        self.setupTextField()
        self.setupLayout()
    }
    
    // MARK: - Overridden
    
    override var canBecomeFirstResponder: Bool {
        return self.textField.canBecomeFirstResponder
    }
    
    override func becomeFirstResponder() -> Bool {
        return self.textField.becomeFirstResponder()
    }
    
    override var canResignFirstResponder: Bool {
        return self.textField.canResignFirstResponder
    }
    
    override func resignFirstResponder() -> Bool {
        return self.textField.resignFirstResponder()
    }
    
    override var isFirstResponder: Bool {
        return self.textField.isFirstResponder
    }
    
    // MARK: - Private
    
    private func setupView() {
        self.backgroundColor = UIColor.clear
    }
    
    private func setupTextField() {
        self.textField.backgroundColor = UIColor.clear
        self.textField.delegate = self
    }
    
    private func setupLayout() {
        self.addSubview(self.textField)
        
        self.textField.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    private func updateTextColor() {
        self.textField.textColor = self.isValid ? self.textColor : self.invalidTextColor
    }
}

// MARK: - UITextFieldDelegate

extension TextFieldView: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
        ) -> Bool {
        
        if let onShouldReplace = self.onShouldReplace {
            return onShouldReplace(textField.text ?? "", range, string)
        } else {
            return true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return self.onShouldReturn(self)
    }
}

// MARK: - TextInputView

extension TextFieldView: TextInputView {
    func observeTextInput(
        onTextInput: @escaping (String?, TextInputView) -> Void,
        disposeBag: DisposeBag
        ) {
        
        self.textField.rx
            .text
            .asDriver()
            .skip(1)
            .drive(onNext: { [weak self] text in
                guard let strongSelf = self else { return }
                
                onTextInput(text, strongSelf)
            })
            .disposed(by: disposeBag)
    }
    
    func observeShouldReplace(onShouldReplace: @escaping (String, NSRange, String) -> Bool) {
        self.onShouldReplace = onShouldReplace
    }
    
    func setValueValid(_ isValid: Bool) {
        self.isValid = isValid
    }
}
