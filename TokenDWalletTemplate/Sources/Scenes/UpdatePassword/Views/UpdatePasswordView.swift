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
        private var fields: [FieldView] = []
        
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
            self.fields.removeAll()
            
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
            fieldView.textField
                .rx
                .text
                .asDriver()
                .drive(onNext: { [weak self] text in
                    self?.onEditField?(field.fieldType, text)
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
                self.fields.append(textField)
                
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
    }
}

extension UpdatePassword.View: UITextFieldDelegate {
    
}

extension UpdatePassword.View {
    
    struct Field {
        let fieldType: UpdatePassword.Model.FieldType
        let title: String
        let text: String?
        let placeholder: String?
        let keyboardType: UIKeyboardType
        let autocapitalize: UITextAutocapitalizationType
        let autocorrection: UITextAutocorrectionType
        let secureInput: Bool
    }
    typealias FieldView = RegisterScene.View.FieldView
}
