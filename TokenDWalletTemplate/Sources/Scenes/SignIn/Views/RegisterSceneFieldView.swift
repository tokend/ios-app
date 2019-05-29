import RxCocoa
import RxSwift
import SnapKit
import UIKit

extension RegisterScene.View {
    
    class FieldView: UIView {
        
        // MARK: - Public properties
        
        let titleLabel: UILabel = UILabel()
        let textField: UITextField = UITextField()
        let actionButton: UIButton = UIButton(type: .custom)
        
        var titleWidth: CGFloat = 80.0 {
            didSet {
                self.updateLabelsLayout()
            }
        }
        
        var textEditingEnabled: Bool = true {
            didSet {
                self.updateTextFieldEditing()
            }
        }
        
        var actionType: RegisterScene.Model.Field.ActionType = .none {
            didSet {
                self.setupActionButton()
                self.updateLabelsLayout()
                self.updateTextFieldEditing()
            }
        }
        
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
            self.backgroundColor = Theme.Colors.textFieldBackgroundColor
            
            self.setupTitleLabel()
            self.setupTextField()
            self.setupLayout()
        }
        
        // MARK: - Public
        
        public func showError() {
            self.titleLabel.textColor = Theme.Colors.textFieldForegroundErrorColor
        }
        
        public override func hideError() {
            self.titleLabel.textColor = Theme.Colors.textFieldForegroundColor
        }
        
        // MARK: - Private
        
        private func setupTitleLabel() {
            self.titleLabel.textAlignment = .left
            self.titleLabel.textColor = Theme.Colors.textFieldForegroundColor
            self.titleLabel.font = Theme.Fonts.textFieldTitleFont
        }
        
        private func setupTextField() {
            self.textField.textAlignment = .left
            self.textField.textColor = Theme.Colors.textFieldForegroundColor
            self.textField.font = Theme.Fonts.textFieldTextFont
        }
        
        private func setupActionButton() {
            let buttonImage: UIImage?
            var isHidden: Bool = false
            
            switch self.actionType {
                
            case .hidePassword:
                buttonImage = Assets.hidePasswordIcon.image
                
            case .none:
                buttonImage = nil
                isHidden = true
                
            case .scanQr:
                buttonImage = Assets.scanQrIcon.image
                
            case .showPassword:
                buttonImage = Assets.showPasswordIcon.image
            }
            self.actionButton.setImage(buttonImage, for: .normal)
            self.actionButton.tintColor = Theme.Colors.darkAccentColor
            self.actionButton.isHidden = isHidden
        }
        
        private func setupLayout() {
            self.addSubview(self.titleLabel)
            self.addSubview(self.textField)
            self.addSubview(self.actionButton)
            
            self.updateLabelsLayout()
        }
        
        private func updateLabelsLayout() {
            self.titleLabel.snp.remakeConstraints { (make) in
                make.leading.top.bottom.equalToSuperview()
                make.width.equalTo(self.titleWidth)
            }
            
            switch self.actionType {
                
            case .none:
                self.actionButton.snp.remakeConstraints { (make) in
                    make.trailing.top.bottom.equalToSuperview()
                    make.width.equalTo(self.actionButton.snp.height)
                }
                self.textField.snp.remakeConstraints { (make) in
                    make.trailing.top.bottom.equalToSuperview()
                    make.leading.equalTo(self.titleLabel.snp.trailing).offset(20.0)
                }
                
            case .hidePassword, .scanQr, .showPassword:
                self.actionButton.snp.remakeConstraints { (make) in
                    make.trailing.top.bottom.equalToSuperview()
                    make.width.equalTo(self.actionButton.snp.height)
                }
                self.textField.snp.remakeConstraints { (make) in
                    make.top.bottom.equalToSuperview()
                    make.leading.equalTo(self.titleLabel.snp.trailing).offset(20.0)
                    make.trailing.equalTo(self.actionButton.snp.leading).offset(-20.0)
                }
            }
        }
        
        private func updateTextFieldEditing() {
            self.textField.isEnabled = self.textEditingEnabled
            switch self.actionType {
                
            case .scanQr:
                self.textField.textColor = Theme.Colors.textFieldForegroundDisabledColor
                
            case .hidePassword, .none, .showPassword:
                self.textField.textColor = self.textEditingEnabled
                    ? Theme.Colors.textFieldForegroundColor
                    : Theme.Colors.textFieldForegroundDisabledColor
            }
        }
    }
}
