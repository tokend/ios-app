import UIKit
import RxCocoa
import RxSwift

// MARK: - TextInputView

protocol TextInputView: class {
    
    var text: String? { get set }
    
    func observeTextInput(
        onTextInput: @escaping (_ text: String?, _ textInputView: TextInputView) -> Void,
        disposeBag: DisposeBag
    )
    func observeShouldReplace(onShouldReplace: @escaping (
        _ currentText: String,
        _ range: NSRange,
        _ replacementString: String
        ) -> Bool)
    
    // MARK: - Validation
    
    func setValueValid(_ isValid: Bool)
}

// MARK: - TextEditingContext

class TextEditingContext <ValueType> {
    
    let textInputView: TextInputView
    let valueFormatter: ValueFormatter<ValueType>
    let valueValidator: ValueValidator<ValueType>
    let callbacks: Callbacks
    
    public var value: ValueType? {
        return self.valueFormatter.valueFromString(self.textInputView.text)
    }
    
    private let disposeBag: DisposeBag = DisposeBag()
    
    init(
        textInputView: TextInputView,
        valueFormatter: ValueFormatter<ValueType>,
        valueValidator: ValueValidator<ValueType>? = nil,
        callbacks: Callbacks
        ) {
        
        let checkedValidator: ValueValidator<ValueType> = valueValidator ?? ValueValidator<ValueType>()
        
        self.textInputView = textInputView
        self.valueFormatter = valueFormatter
        self.valueValidator = checkedValidator
        self.callbacks = callbacks
        
        textInputView.observeTextInput(
            onTextInput: { (text, textInputView) in
                let value = valueFormatter.valueFromString(text)
                callbacks.onInputValue(value)
                
                let isValid = checkedValidator.validate(value: value)
                textInputView.setValueValid(isValid)
        },
            disposeBag: self.disposeBag
        )
        
        textInputView.observeShouldReplace(onShouldReplace: { (currentText, range, replacementString) in
            let nsString = currentText as NSString
            
            let resultString = nsString.replacingCharacters(in: range, with: replacementString)
            
            guard resultString.count > 0 else {
                return true
            }
            
            let value = valueFormatter.valueFromString(resultString)
            return value != nil
        })
    }
    
    func setValue(_ value: ValueType?) {
        guard let value = value else {
            self.textInputView.text = nil
            return
        }
        
        let string = self.valueFormatter.stringFromValue(value)
        self.textInputView.text = string
        
        let isValid = self.valueValidator.validate(value: value)
        self.textInputView.setValueValid(isValid)
    }
}

// MARK: -

extension TextEditingContext {
    struct Callbacks {
        let onInputValue: (_ value: ValueType?) -> Void
    }
}
