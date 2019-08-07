import UIKit

extension ConfirmationScene.View {
    class TitleTextViewModel: ConfirmationScene.Model.CellViewModel {
        
        // MARK: - Public properties
        
        var value: String?
        
        // MARK: -
        
        init(
            title: String,
            cellType: ConfirmationScene.Model.CellModel.CellType,
            identifier: ConfirmationScene.CellIdentifier,
            value: String?
            ) {
            
            self.value = value
            
            super.init(
                title: title,
                cellType: cellType,
                identifier: identifier
            )
        }
    }
    
    class TitleTextView: UIView {
        
        // MARK: - Public properties
        
        var model: TitleTextViewModel? {
            didSet {
                self.updateFromModel()
            }
        }
        
        // MARK: - Private properties
        
        private let titleLabel: UILabel = UILabel()
        private let textLabel: UILabel = UILabel()
        
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
            self.setupTextLabel()
            self.setupLayout()
        }
        
        // MARK: - Public
        
        // MARK: - Private
        
        private func updateFromModel() {
            self.titleLabel.text = self.model?.title
            self.textLabel.text = self.model?.value
        }
        
        // MARK: - Setup
        
        private func setupView() {
            self.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupTitleLabel() {
            SharedViewsBuilder.configureInputForm(titleLabel: self.titleLabel)
            self.titleLabel.numberOfLines = 0
        }
        
        private func setupTextLabel() {
            SharedViewsBuilder.configureInputForm(valueLabel: self.textLabel)
            self.textLabel.textAlignment = .right
            self.textLabel.numberOfLines = 0
        }
        
        private func setupLayout() {
            self.addSubview(self.titleLabel)
            self.addSubview(self.textLabel)
            
            self.titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            self.textLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

            self.titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            self.textLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
            
            self.titleLabel.snp.makeConstraints { (make) in
                make.leading.equalToSuperview().inset(20.0)
                make.centerY.equalToSuperview()
                make.top.bottom.equalToSuperview().inset(14.0)
            }
            
            self.textLabel.snp.makeConstraints { (make) in
                make.leading.equalTo(self.titleLabel.snp.trailing).offset(10.0)
                make.top.bottom.equalToSuperview().inset(14.0)
                make.trailing.equalToSuperview().inset(20.0)
            }
        }
    }
}
