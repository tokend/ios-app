import RxCocoa
import RxSwift
import SnapKit
import UIKit

extension RegisterScene.View {
    
    class FieldView: UIView {
        
        // MARK: - Public properties
        
        let titleLabel: UILabel = UILabel()
        let textField: UITextField = UITextField()
        let scanButton: UIButton = UIButton(type: .custom)
        
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
        
        var scanButtonHidden: Bool {
            get { return self.scanButton.isHidden }
            set {
                self.scanButton.isHidden = newValue
                self.updateTextFieldEditing()
                self.updateLabelsLayout()
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
            self.setupScanButton()
            self.setupLayout()
            self.scanButtonHidden = true
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
        
        private func setupScanButton() {
            self.scanButton.setImage(#imageLiteral(resourceName: "Scan QR icon"), for: .normal)
            self.scanButton.tintColor = Theme.Colors.mainColor
        }
        
        private func setupLayout() {
            self.addSubview(self.titleLabel)
            self.addSubview(self.textField)
            self.addSubview(self.scanButton)
            
            self.updateLabelsLayout()
        }
        
        private func updateLabelsLayout() {
            self.titleLabel.snp.remakeConstraints { (make) in
                make.leading.top.bottom.equalToSuperview()
                make.width.equalTo(self.titleWidth)
            }
            
            if self.scanButtonHidden {
                self.scanButton.snp.remakeConstraints { (make) in
                    make.trailing.top.bottom.equalToSuperview()
                    make.width.equalTo(self.scanButton.snp.height)
                }
                self.textField.snp.remakeConstraints { (make) in
                    make.trailing.top.bottom.equalToSuperview()
                    make.leading.equalTo(self.titleLabel.snp.trailing).offset(20.0)
                }
            } else {
                self.scanButton.snp.remakeConstraints { (make) in
                    make.trailing.top.bottom.equalToSuperview()
                    make.width.equalTo(self.scanButton.snp.height)
                }
                self.textField.snp.remakeConstraints { (make) in
                    make.top.bottom.equalToSuperview()
                    make.leading.equalTo(self.titleLabel.snp.trailing).offset(20.0)
                    make.trailing.equalTo(self.scanButton.snp.leading).offset(-20.0)
                }
            }
        }
        
        private func updateTextFieldEditing() {
            self.textField.isEnabled = self.textEditingEnabled && self.scanButtonHidden
            self.textField.textColor = self.textField.isEnabled
                ? Theme.Colors.textFieldForegroundColor
                : Theme.Colors.textFieldForegroundDisabledColor
        }
    }
}
