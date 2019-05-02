import UIKit
import RxSwift
import RxCocoa

extension ConfirmationScene.View {
    class TitleTextEditViewModel: ConfirmationScene.Model.CellViewModel, CellViewModel {
        
        // MARK: - Public properties
        
        var title: String?
        var placeholder: String?
        var maxCharacters: Int
        
        // MARK: -
        
        init(
            hint: String?,
            cellType: ConfirmationScene.Model.CellModel.CellType,
            identifier: ConfirmationScene.CellIdentifier,
            title: String?,
            placeholder: String?,
            maxCharacters: Int = 0
            ) {
            
            self.title = title
            self.placeholder = placeholder
            self.maxCharacters = maxCharacters
            
            super.init(
                hint: hint,
                cellType: cellType,
                identifier: identifier
            )
        }
        
        func setup(cell: TitleTextEditView) {
            cell.hint = self.hint
            cell.title = self.title
            cell.maxCharacters = self.maxCharacters
            cell.placeholder = self.placeholder
            cell.identifier = self.identifier
        }
    }
    
    class TitleTextEditView: BaseCell {
        
        // MARK: - Public properties
        
        var hint: String? {
            get { return self.titleLabel.text }
            set { self.titleLabel.text = newValue }
        }
        
        var title: String? {
            get { return self.textView.text }
            set { self.textView.text = newValue }
        }
        
        var maxCharacters: Int = 0 {
            didSet {
                self.updatePlaceholderLabel()
            }
        }
        
        var placeholder: String? {
            get { return self.placeholderLabel.text }
            set {
                self.placeholderLabel.text = newValue
                self.updatePlaceholderLabel()
            }
        }
        
        var identifier: ConfirmationScene.CellIdentifier?
        
        var onEdit: ((_ identifier: ConfirmationScene.CellIdentifier, _ value: String?) -> Void)?
        
        // MARK: - Private properties
        
        private let titleLabel: UILabel = UILabel()
        private let maxCharactersLabel: UILabel = UILabel()
        private let placeholderLabel: UILabel = UILabel()
        private let textView: UITextView = UITextView()
        
        private let disposeBag = DisposeBag()
        
        // MARK: -
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
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
        
        private func updateMaxCharactersLabel() {
            guard self.maxCharacters > 0 else {
                self.maxCharactersLabel.isHidden = true
                return
            }
            
            let charactersCount = self.textView.text.count
            self.maxCharactersLabel.text = "\(charactersCount)/\(self.maxCharacters)"
            self.maxCharactersLabel.textColor = charactersCount <= self.maxCharacters
                ? Theme.Colors.sideTextOnContentBackgroundColor
                : Theme.Colors.negativeColor
            self.maxCharactersLabel.isHidden = false
        }
        
        private func updatePlaceholderLabel() {
            self.placeholderLabel.text = self.placeholder
            
            let charactersCount = self.textView.text.count
            self.placeholderLabel.isHidden = charactersCount > 0
        }
        
        // MARK: - Setup
        
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
                    
                    guard let identifier = self?.identifier else { return }
                    self?.onEdit?(identifier, text)
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
