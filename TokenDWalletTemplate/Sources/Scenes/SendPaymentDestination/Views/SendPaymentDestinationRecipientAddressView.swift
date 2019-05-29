import UIKit
import RxCocoa
import RxSwift

extension SendPaymentDestination {
    class RecipientAddressView: UIView {
        
        // MARK: - Public properties
        
        var placeholder: String? {
            get { return self.addressField.placeholder }
            set { self.addressField.placeholder = newValue }
        }
        
        var address: String? {
            get { return self.addressField.text }
            set { self.addressField.text = newValue }
        }
        
        var onAddressEdit: ((_ address: String?) -> Void)?
        var onQRAction: (() -> Void)?
        
        // MARK: - Private properties
        
        private let titleLabel: UILabel = UILabel()
        private let scanQRButton: UIButton = UIButton(type: .custom)
        private let addressField: UITextField = UITextField()
        private let separatorLine: UIView = UIView()
        
        private let disposeBag = DisposeBag()
        
        // MARK: -
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.customInit()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            
            self.customInit()
        }
        
        // MARK: - Private
        
        private func customInit() {
            self.setupView()
            self.setupSeparatorLine()
            self.setupScanQRButton()
            self.setupAddressField()
            self.setupLayout()
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupSeparatorLine() {
            self.separatorLine.backgroundColor = Theme.Colors.separatorOnContentBackgroundColor
        }
        
        private func setupScanQRButton() {
            self.scanQRButton.setImage(#imageLiteral(resourceName: "Scan QR icon"), for: .normal)
            self.scanQRButton.tintColor = Theme.Colors.darkAccentColor
            self.scanQRButton
                .rx
                .controlEvent(.touchUpInside)
                .asDriver()
                .drive(onNext: { [weak self] in
                    self?.onQRAction?()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupAddressField() {
            self.addressField.textColor = Theme.Colors.textOnContentBackgroundColor
            self.addressField.autocapitalizationType = .none
            self.addressField.autocorrectionType = .no
            self.addressField.keyboardType = .emailAddress
            self.addressField.spellCheckingType = .no
            self.addressField.delegate = self
            
            self.addressField
                .rx
                .text
                .asDriver()
                .drive(onNext: { [weak self] (text) in
                    self?.onAddressEdit?(text)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupLayout() {
            self.addSubview(self.addressField)
            self.addSubview(self.scanQRButton)
            self.addSubview(self.separatorLine)
            
            let scanButtonEdgeInset: CGFloat = 5.0
            self.scanQRButton.contentEdgeInsets = UIEdgeInsets(
                top: scanButtonEdgeInset,
                left: scanButtonEdgeInset,
                bottom: scanButtonEdgeInset,
                right: scanButtonEdgeInset
            )
            self.scanQRButton.snp.makeConstraints { (make) in
                make.trailing.equalToSuperview().inset(10.0 - scanButtonEdgeInset)
                make.centerY.equalTo(self.addressField.snp.centerY)
                make.width.height.equalTo(35.0)
            }
            
            self.addressField.snp.makeConstraints { (make) in
                make.leading.equalToSuperview().inset(15.0)
                make.trailing.equalTo(self.scanQRButton.snp.leading).offset(-15.0)
                make.top.equalToSuperview().offset(20.0)
            }
            
            self.separatorLine.snp.makeConstraints { (make) in
                make.leading.trailing.equalTo(self.addressField)
                make.top.equalTo(self.addressField.snp.bottom)
                make.bottom.equalToSuperview().inset(20.0)
                make.height.equalTo(1.0)
            }
        }
    }
}

// MARK: - UITextFieldDelegate

extension SendPaymentDestination.RecipientAddressView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
