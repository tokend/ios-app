import RxCocoa
import RxSwift
import SnapKit
import UIKit

extension UpdatePassword {
    class View: UIView {
        
        // MARK: - Public properties
        
        let marginInset: CGFloat = 20.0
        let separatorHeight: CGFloat = 1.0
        let fieldHeight: CGFloat = 44.0
        
        // MARK: - Private properties
        
        private let contentView = UIView()
        private var fields: [Field] = []
        private var fieldViews: [FieldView] = []
        
        private let disposeBag = DisposeBag()
        
        // MARK: - Callbacks
        
        var onEditField: ((_ fieldType: UpdatePassword.Model.FieldType, _ text: String?) -> Void)?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.customInit()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            
            self.customInit()
        }
        
        private func customInit() {
            self.backgroundColor = Theme.Colors.textFieldBackgroundColor
            
            self.setupView()
            self.setupLayout()
        }
        
        // MARK: - Public
        
        public func setupFields(_ fields: [Field]) {
            self.contentView.subviews.forEach { (fieldView) in
                fieldView.removeFromSuperview()
            }
            self.fieldViews.removeAll()
            
            self.fields = fields
            self.layoutFields(fields)
        }
        
        // MARK: - Private
        
        private func setupContentView() {
            self.contentView.backgroundColor = Theme.Colors.textFieldBackgroundColor
        }
        
        private func setupFieldView(_ fieldView: FieldView, field: Field) {
            fieldView.titleWidth = 100.0
            fieldView.titleLabel.text = field.title
            
            fieldView.textField.text = field.text
            fieldView.textField.placeholder = field.placeholder
            fieldView.textField.keyboardType = field.keyboardType
            fieldView.textField.autocapitalizationType = field.autocapitalize
            fieldView.textField.autocorrectionType = field.autocorrection
            fieldView.textField.isSecureTextEntry = field.secureInput
            fieldView.textField.delegate = self
            
            switch field.fieldType {
                
            case .newPassword, .oldPassword, .confirmPassword:
                fieldView.actionType = field.secureInput
                    ? .showPassword
                    : .hidePassword
                
                fieldView.actionButton.rx
                    .controlEvent(.touchUpInside)
                    .asDriver()
                    .drive(onNext: { [weak self] in
                        self?.changePasswordVisibility(
                            field: field,
                            actionType: fieldView.actionType
                        )
                    })
                    .disposed(by: self.disposeBag)
                
            case .email, .seed:
                break
            }
            
            fieldView.textField
                .rx
                .text
                .asDriver()
                .drive(onNext: { [weak self] text in
                    self?.onEditField?(field.fieldType, text)
                    self?.updateFieldText(field: field, text: text)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupSeparator(_ separator: UIView) {
            separator.backgroundColor = Theme.Colors.separatorOnContentBackgroundColor
            separator.isUserInteractionEnabled = false
        }
        
        private func setupView() {
            self.setupContentView()
        }
        
        private func setupLayout() {
            self.addSubview(self.contentView)
            
            self.contentView.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalToSuperview().inset(30)
            }
        }
        
        private func layoutFields(_ fields: [Field]) {
            guard fields.count > 0 else { return }
            
            var prevField: FieldView?
            var prevSeparator: UIView = UIView()
            self.setupSeparator(prevSeparator)
            self.contentView.addSubview(prevSeparator)
            
            prevSeparator.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(self.marginInset)
                make.top.equalToSuperview()
                make.height.equalTo(self.separatorHeight)
            }
            
            for field in fields {
                let textField = FieldView()
                self.setupFieldView(textField, field: field)
                
                self.contentView.addSubview(textField)
                textField.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.marginInset)
                    make.height.equalTo(self.fieldHeight)
                    if let prevField = prevField {
                        make.top.equalTo(prevField.snp.bottom).offset(ceil(self.separatorHeight) + 2.0)
                    } else {
                        make.top.equalToSuperview().offset(ceil(self.separatorHeight) + 1.0)
                    }
                }
                prevField = textField
                self.fieldViews.append(textField)
                
                let separator = UIView()
                self.setupSeparator(separator)
                self.contentView.addSubview(separator)
                separator.snp.makeConstraints { (make) in
                    make.leading.trailing.equalTo(prevSeparator)
                    make.height.equalTo(self.separatorHeight)
                    make.top.equalTo(textField.snp.bottom).offset(1.0)
                }
                prevSeparator = separator
            }
            
            prevSeparator.snp.makeConstraints { (make) in
                make.bottom.equalToSuperview()
            }
        }
        
        private func changePasswordVisibility(
            field: View.Field,
            actionType: ActionType
            ) {
            
            guard var fieldToChange = self.fields.first(where: { (storedField) -> Bool in
                return storedField.fieldType == field.fieldType
            }), let index = self.fields.indexOf(fieldToChange) else {
                return
            }
            fieldToChange.secureInput = !fieldToChange.secureInput
            self.fields[index] = fieldToChange
            self.setupFields(self.fields)
        }
        
        private func updateFieldText(
            field: View.Field,
            text: String?
            ) {
            
            guard var fieldToChange = self.fields.first(where: { (storedField) -> Bool in
                return storedField.fieldType == field.fieldType
            }), let index = self.fields.indexOf(fieldToChange) else {
                return
            }
            fieldToChange.text = text
            self.fields[index] = fieldToChange
        }
    }
}

extension UpdatePassword.View: UITextFieldDelegate {
    
}

extension UpdatePassword.View {
    
    struct Field: Equatable {
        let fieldType: UpdatePassword.Model.FieldType
        let title: String
        var text: String?
        let placeholder: String?
        let keyboardType: UIKeyboardType
        let autocapitalize: UITextAutocapitalizationType
        let autocorrection: UITextAutocorrectionType
        var secureInput: Bool
    }
    typealias FieldView = RegisterScene.View.FieldView
    typealias ActionType = RegisterScene.Model.Field.ActionType
}
