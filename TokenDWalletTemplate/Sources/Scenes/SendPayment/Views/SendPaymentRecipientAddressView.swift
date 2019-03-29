import UIKit
import RxCocoa
import RxSwift

extension SendPayment {
    class RecipientAddressView: UIView {
        
        // MARK: - Public properties
        
        var title: String? {
            get { return self.titleLabel.text }
            set { self.titleLabel.text = newValue }
        }
        
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
        var onSelectAccount: (() -> Void)?
        
        // MARK: - Private properties
        
        private let titleLabel: UILabel = UILabel()
        private let scanQRButton: UIButton = UIButton(type: .custom)
        private let addressField: UITextField = UITextField()
        private let selectAccountView: UIView = UIView()
        
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
        
        private func customInit() {
            self.setupView()
            self.setupTitleLabel()
            self.setupScanQRButton()
            self.setupAddressField()
            self.setupSelectAccountView()
            self.setupLayout()
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupTitleLabel() {
            self.titleLabel.text = Localized(.account_id_or_email_colon)
            self.titleLabel.font = Theme.Fonts.textFieldTitleFont
            self.titleLabel.textAlignment = .left
            self.titleLabel.textColor = Theme.Colors.textOnContentBackgroundColor
        }
        
        private func setupScanQRButton() {
            self.scanQRButton.setImage(#imageLiteral(resourceName: "Scan QR icon"), for: .normal)
            self.scanQRButton.tintColor = Theme.Colors.mainColor
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
            self.addressField.placeholder = Localized(.enter_account_id_or_email)
            self.addressField.textColor = Theme.Colors.textOnContentBackgroundColor
            self.addressField.font = Theme.Fonts.textFieldTextFont
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
        
        private func setupSelectAccountView() {
            self.selectAccountView.backgroundColor = Theme.Colors.contentBackgroundColor
            
            let selectButton = UIButton(type: .custom)
            selectButton.setTitleColor(Theme.Colors.accentColor, for: .normal)
            selectButton.backgroundColor = UIColor.clear
            
            selectButton.setTitle(Localized(.select_contact), for: .normal)
            self.selectAccountView.addSubview(selectButton)
            selectButton.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            
            selectButton
                .rx
                .controlEvent(.touchUpInside)
                .asDriver()
                .drive(onNext: { [weak self] in
                    self?.onSelectAccount?()
                })
                .disposed(by: self.disposeBag)
            
            self.addressField.inputAccessoryView = self.selectAccountView
        }
        
        private func setupLayout() {
            self.addSubview(self.titleLabel)
            self.addSubview(self.addressField)
            self.addSubview(self.scanQRButton)
            
            self.titleLabel.snp.makeConstraints { (make) in
                make.leading.equalToSuperview().inset(20.0)
                make.top.equalToSuperview().inset(14.0)
            }
            
            let scanButtonEdgeInset: CGFloat = 5.0
            self.scanQRButton.contentEdgeInsets = UIEdgeInsets(
                top: scanButtonEdgeInset,
                left: scanButtonEdgeInset,
                bottom: scanButtonEdgeInset,
                right: scanButtonEdgeInset
            )
            self.scanQRButton.snp.makeConstraints { (make) in
                make.trailing.equalToSuperview().inset(20.0 - scanButtonEdgeInset)
                make.top.equalToSuperview().inset(14.0 - scanButtonEdgeInset)
            }
            
            self.addressField.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(20.0)
                make.top.equalTo(self.titleLabel.snp.bottom).offset(14.0)
                make.bottom.equalToSuperview().inset(14.0)
            }
            
            self.selectAccountView.frame = CGRect(
                x: 0.0, y: 0.0,
                width: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height),
                height: 44.0
            )
            self.selectAccountView.autoresizingMask = [.flexibleWidth]
        }
    }
}

// MARK: - UITextFieldDelegate

extension SendPayment.RecipientAddressView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
