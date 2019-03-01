import UIKit
import RxSwift
import RxCocoa

extension ConfirmationScene.View {
    class TitleTextEditViewModel: ConfirmationScene.Model.CellViewModel {
        
        // MARK: - Public properties
        
        var value: String?
        var placeholder: String?
        var maxCharacters: Int
        
        // MARK: -
        
        init(
            title: String,
            cellType: ConfirmationScene.Model.CellModel.CellType,
            identifier: ConfirmationScene.CellIdentifier,
            value: String?,
            placeholder: String?,
            maxCharacters: Int = 0
            ) {
            
            self.value = value
            self.placeholder = placeholder
            self.maxCharacters = maxCharacters
            
            super.init(
                title: title,
                cellType: cellType,
                identifier: identifier
            )
        }
    }
    
    class TitleTextEditView: UIView {
        
        // MARK: - Public properties
        
        var model: TitleTextEditViewModel? {
            didSet {
                self.updateFromModel()
            }
        }
        
        var onEdit: ((_ identifier: ConfirmationScene.CellIdentifier, _ value: String?) -> Void)?

        // MARK: - Private properties
        
        private let titleLabel: UILabel = UILabel()
        private let maxCharactersLabel: UILabel = UILabel()
        private let placeholderLabel: UILabel = UILabel()
        private let textView: UITextView = UITextView()
        
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
            self.setupMaxCharactersLabel()
            self.setupPlaceholderLabel()
            self.setupTextView()
            self.setupLayout()
        }
        
        // MARK: - Public
        
        // MARK: - Private
        
        private func updateFromModel() {
            self.titleLabel.text = self.model?.title
            self.textView.text = self.model?.value
            self.updateMaxCharactersLabel()
            self.updatePlaceholderLabel()
        }
        
        private func updateMaxCharactersLabel() {
            guard let maxCharacters = self.model?.maxCharacters, maxCharacters > 0 else {
                self.maxCharactersLabel.isHidden = true
                return
            }
            
            let charactersCount = self.textView.text.count
            self.maxCharactersLabel.text = "\(charactersCount)/\(maxCharacters)"
            self.maxCharactersLabel.textColor = charactersCount <= maxCharacters
                ? Theme.Colors.sideTextOnContentBackgroundColor
                : Theme.Colors.negativeColor
            self.maxCharactersLabel.isHidden = false
        }
        
        private func updatePlaceholderLabel() {
            self.placeholderLabel.text = self.model?.placeholder
            
            let charactersCount = self.textView.text.count
            self.placeholderLabel.isHidden = charactersCount > 0
        }
        
        // MARK: - Setup
        
        private func setupView() {
            self.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupTitleLabel() {
            SharedViewsBuilder.configureInputForm(titleLabel: self.titleLabel)
            self.maxCharactersLabel.textAlignment = .left
        }
        
        private func setupMaxCharactersLabel() {
            SharedViewsBuilder.configureInputForm(titleLabel: self.maxCharactersLabel)
            self.maxCharactersLabel.textAlignment = .right
        }
        
        private func setupPlaceholderLabel() {
            SharedViewsBuilder.configureInputForm(placeholderLabel: self.placeholderLabel)
            self.placeholderLabel.textAlignment = .left
        }
        
        private func setupTextView() {
            SharedViewsBuilder.configureInputForm(textView: self.textView)
            self.textView.backgroundColor = UIColor.clear
            self.textView.delegate = self
            
            self.textView
                .rx
                .text
                .asDriver()
                .drive(onNext: { [weak self] (text) in
                    self?.updateMaxCharactersLabel()
                    self?.updatePlaceholderLabel()
                    
                    guard let model = self?.model else { return }
                    
                    self?.onEdit?(model.identifier, text)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupLayout() {
            self.addSubview(self.titleLabel)
            self.addSubview(self.maxCharactersLabel)
            self.addSubview(self.textView)
            self.addSubview(self.placeholderLabel)
            
            self.titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            self.maxCharactersLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            
            self.titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
            self.maxCharactersLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            
            self.titleLabel.snp.makeConstraints { (make) in
                make.leading.equalToSuperview().inset(20.0)
                make.top.equalToSuperview().inset(14.0)
            }
            
            self.maxCharactersLabel.snp.makeConstraints { (make) in
                make.trailing.equalToSuperview().inset(20.0)
                make.leading.equalTo(self.titleLabel.snp.trailing).offset(20.0)
                make.centerY.equalTo(self.titleLabel)
            }
            
            self.textView.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(20.0)
                make.top.equalTo(self.titleLabel.snp.bottom).offset(14.0)
                make.bottom.equalToSuperview().inset(14.0)
                make.height.greaterThanOrEqualTo(80.0)
            }
            
            self.placeholderLabel.snp.makeConstraints { (make) in
                make.leading.trailing.top.equalTo(self.textView)
            }
        }
    }
}

extension ConfirmationScene.View.TitleTextEditView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}
