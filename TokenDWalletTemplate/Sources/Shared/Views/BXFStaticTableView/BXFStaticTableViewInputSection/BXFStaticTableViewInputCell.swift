//import UIKit
//
//class BXFStaticTableViewInputCell: UIControl {
//
//    typealias EditTextCallback = ((_ text: String?, _ cell: BXFStaticTableViewInputCell) -> Void)
//    typealias ShouldReturnCallback = ((_ cell: BXFStaticTableViewInputCell) -> Bool)
//    typealias DidBeginEditingCallback = ((_ cell: BXFStaticTableViewInputCell) -> Void)
//    typealias DidEndEditingCallback = ((_ cell: BXFStaticTableViewInputCell) -> Void)
//
//    private let textField: UITextField = UITextField()
//
//    // MARK: Public properties
//
//    var text: String? {
//        get { return self.textField.text }
//        set { self.textField.text = newValue }
//    }
//
//    var placeholder: String? {
//        get { return self.textField.placeholder }
//        set { self.textField.placeholder = newValue }
//    }
//
//    var autocapitalizationType: UITextAutocapitalizationType {
//        get { return self.textField.autocapitalizationType }
//        set { self.textField.autocapitalizationType = newValue }
//    }
//
//    var autocorrectionType: UITextAutocorrectionType {
//        get { return self.textField.autocorrectionType }
//        set { self.textField.autocorrectionType = newValue }
//    }
//    
//    var keyboardType: UIKeyboardType {
//        get { return self.textField.keyboardType }
//        set { self.textField.keyboardType = newValue }
//    }
//
//    var returnKeyType: UIReturnKeyType {
//        get { return self.textField.returnKeyType }
//        set { self.textField.returnKeyType = newValue }
//    }
//
//    var isSecureTextEntry: Bool {
//        get { return self.textField.isSecureTextEntry }
//        set { self.textField.isSecureTextEntry = newValue }
//    }
//
//    override var inputAccessoryView: UIView? {
//        get { return self.textField.inputAccessoryView }
//        set { self.textField.inputAccessoryView = newValue }
//    }
//
//    // MARK: Callbacks
//
//    var onEditText: EditTextCallback?
//    var onShouldReturn: ShouldReturnCallback = { _ in return true }
//    var onDidBeginEditing: DidBeginEditingCallback?
//    var onDidEndEditing: DidEndEditingCallback?
//
//    // MARK: -
//
//    static func instantiate() -> BXFStaticTableViewInputCell {
//        return BXFStaticTableViewInputCell()
//    }
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//
//        self.commonInit()
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//
//        self.commonInit()
//    }
//
//    private func commonInit() {
//        self.backgroundColor = UIColor.TableView.Grouped.Cell.background
//
//        self.textField.textColor = UIColor.Textfield.text
//        self.textField.placeholder = Localized(.set_placeholder).localized
//        self.textField.font = UIFont.TableView.Grouped.Cell.textfield
//        self.textField.keyboardType = .default
//        self.textField.backgroundColor = UIColor.TableView.Grouped.Cell.background
//        self.textField.delegate = self
//        self.textField.addTarget(self, action: #selector(self.textFieldDidEditText(_:)), for: .editingChanged)
//
//        self.addSubview(self.textField)
//        self.textField.snp.makeConstraints { (make) in
//            make.leading.trailing.equalToSuperview().inset(15.0)
//            make.top.bottom.equalToSuperview()
//            make.height.equalTo(44.0)
//        }
//    }
//
//    // MARK: - Overridden
//
//    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
//        super.endTracking(touch, with: event)
//
//        if self.isTouchInside, !self.textField.isFirstResponder {
//            self.textField.becomeFirstResponder()
//        }
//    }
//
//    override var canBecomeFirstResponder: Bool {
//        return self.textField.canBecomeFirstResponder
//    }
//
//    @discardableResult override func becomeFirstResponder() -> Bool {
//        return self.textField.becomeFirstResponder()
//    }
//
//    override var isFirstResponder: Bool {
//        return self.textField.isFirstResponder
//    }
//
//    @discardableResult override func resignFirstResponder() -> Bool {
//        return self.textField.resignFirstResponder()
//    }
//
//    override func shake(
//        direction: ShakeDirection,
//        totalDuration: TimeInterval,
//        completion: (() -> Void)?
//        ) -> UIView? {
//        
//        self.textField.shake(
//            direction: direction,
//            totalDuration: totalDuration,
//            completion: completion
//        )
//        return self
//    }
//
//    override func shake(
//        direction: ShakeDirection,
//        numberOfTimes: Int,
//        totalDuration: TimeInterval,
//        completion: (() -> Void)?
//        ) -> UIView? {
//
//        self.textField.shake(
//            direction: direction,
//            numberOfTimes: numberOfTimes,
//            totalDuration: totalDuration,
//            completion: completion
//        )
//        return self
//    }
//}
//
//// MARK: - UITextFieldDelegate
//
//extension BXFStaticTableViewInputCell: UITextFieldDelegate {
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        return self.onShouldReturn(self)
//    }
//
//    @objc func textFieldDidEditText(_ textField: UITextField) {
//        self.onEditText?(textField.text, self)
//    }
//    
//    func textFieldDidBeginEditing(_ textField: UITextField) {
//        self.onDidBeginEditing?(self)
//    }
//
//    func textFieldDidEndEditing(_ textField: UITextField) {
//        self.onDidEndEditing?(self)
//    }
//}
