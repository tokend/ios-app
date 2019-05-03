import UIKit
import RxSwift
import RxCocoa

extension SendPaymentAmount {
    
    class DescriptionTextView: UIView {
        
        // MARK: - Public properties
        
        var onEdit: ((_ value: String?) -> Void)?
        
        // MARK: - Private properties
        
        private let separatorView: UIView = UIView()
        private let iconView: UIImageView = UIImageView()
        private let maxCharactersLabel: UILabel = UILabel()
        private let placeholderLabel: UILabel = UILabel()
        private let textField: UITextField = UITextField()
        
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
            self.setupSeparatorView()
            self.setupIconView()
            self.setupMaxCharactersLabel()
            self.setupPlaceholderLabel()
            self.setupTextField()
            self.setupLayout()
        }
        
        // MARK: - Setup
        
        private func setupView() {
            self.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupSeparatorView() {
            self.separatorView.backgroundColor = Theme.Colors.separatorOnContentBackgroundColor
        }
        
        private func setupIconView() {
            self.iconView.backgroundColor = Theme.Colors.contentBackgroundColor
            self.iconView.image = Assets.comment.image
            self.iconView.tintColor = Theme.Colors.separatorOnContentBackgroundColor
        }
        
        private func setupMaxCharactersLabel() {
            SharedViewsBuilder.configureInputForm(titleLabel: self.maxCharactersLabel)
            self.maxCharactersLabel.textAlignment = .right
        }
        
        private func setupPlaceholderLabel() {
            SharedViewsBuilder.configureInputForm(placeholderLabel: self.placeholderLabel)
            self.placeholderLabel.textAlignment = .left
        }
        
        private func setupTextField() {
            self.textField.backgroundColor = Theme.Colors.contentBackgroundColor
            self.textField.autocorrectionType = .no
            
            self.textField
                .rx
                .text
                .asDriver()
                .drive(onNext: { [weak self] (text) in
                    self?.onEdit?(text)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupLayout() {
            self.addSubview(self.separatorView)
            self.addSubview(self.iconView)
            self.addSubview(self.textField)
            self.addSubview(self.placeholderLabel)
            
            self.separatorView.snp.makeConstraints { (make) in
                make.top.leading.trailing.equalToSuperview()
                make.height.equalTo(1.0)
            }
            
            self.iconView.snp.makeConstraints { (make) in
                make.leading.equalToSuperview().inset(20.0)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(24)
            }
            
            self.textField.snp.makeConstraints { (make) in
                make.leading.equalTo(self.iconView.snp.trailing).offset(20.0)
                make.trailing.equalToSuperview().inset(20.0)
                make.top.equalTo(self.separatorView.snp.bottom).inset(-10.0)
                make.bottom.equalToSuperview().inset(15.0)
            }
            
            self.placeholderLabel.snp.makeConstraints { (make) in
                make.leading.trailing.top.equalTo(self.textField)
            }
        }
    }
}
