import UIKit

extension ConfirmationScene.View {
    class TitleTextViewModel: ConfirmationScene.Model.CellViewModel, CellViewModel {
        
        // MARK: - Public properties
        
        var title: String?
        var icon: UIImage?
        
        // MARK: -
        
        init(
            hint: String?,
            cellType: ConfirmationScene.Model.CellModel.CellType,
            identifier: ConfirmationScene.CellIdentifier,
            isDisabled: Bool,
            title: String?,
            icon: UIImage?
            ) {
            
            self.title = title
            self.icon = icon
            
            super.init(
                hint: hint,
                cellType: cellType,
                identifier: identifier,
                isDisabled: isDisabled
            )
        }
        
        func setup(cell: TitleTextView) {
            cell.hint = self.hint
            cell.title = self.title
            cell.icon = self.icon
            cell.isDisabled = self.isDisabled
        }
    }
    
    class TitleTextView: BaseCell {
        
        // MARK: - Public properties
        
        public var icon: UIImage? {
            get { return self.iconView.image }
            set { self.iconView.image = newValue }
        }
        
        public var title: String? {
            get { return self.titleLabel.text }
            set { self.titleLabel.text = newValue }
        }
        
        public var hint: String? {
            get { return self.hintLabel.text }
            set {
                self.hintLabel.text = newValue
                self.updateLayout()
            }
        }
        
        public var isDisabled: Bool = false {
            didSet {
                self.updateDisability()
            }
        }
        
        private let iconView: UIImageView = UIImageView()
        private let titleLabel: UILabel = UILabel()
        private let hintLabel: UILabel = UILabel()
        
        // MARK: -
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            self.commonInit()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - Private
        
        private func updateDisability() {
            if self.isDisabled {
                self.titleLabel.textColor = Theme.Colors.textFieldForegroundDisabledColor
                self.hintLabel.textColor = Theme.Colors.textFieldForegroundDisabledColor
            } else {
                self.titleLabel.textColor = Theme.Colors.textFieldForegroundColor
                self.hintLabel.textColor = Theme.Colors.textFieldForegroundColor
            }
        }
        
        private func commonInit() {
            self.setupView()
            self.setupIconView()
            self.setupTitleLabel()
            self.setupHintLabel()
            
            self.setupLayout()
        }
        
        private func setupIconView() {
            self.iconView.contentMode = .scaleAspectFit
            self.iconView.tintColor = Theme.Colors.darkAccentColor
        }
        
        private func setupTitleLabel() {
            self.titleLabel.font = Theme.Fonts.plainTextFont
            self.titleLabel.textAlignment = .left
            self.titleLabel.textColor = Theme.Colors.textOnContentBackgroundColor
            self.titleLabel.backgroundColor = Theme.Colors.contentBackgroundColor
            self.titleLabel.numberOfLines = 0
        }
        
        private func setupHintLabel() {
            self.hintLabel.font = Theme.Fonts.smallTextFont
            self.hintLabel.textAlignment = .left
            self.hintLabel.textColor = Theme.Colors.sideTextOnContentBackgroundColor
            self.hintLabel.backgroundColor = Theme.Colors.contentBackgroundColor
            self.hintLabel.numberOfLines = 1
        }
        
        private func setupLayout() {
            self.addSubview(self.iconView)
            self.addSubview(self.titleLabel)
            
            self.titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            self.titleLabel.setContentHuggingPriority(.required, for: .horizontal)
            
            self.iconView.snp.makeConstraints { (make) in
                make.leading.equalToSuperview().inset(self.sideInset)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(self.iconSize)
            }
            
            self.updateLayout()
        }
        
        private func updateLayout() {
            if let hint = self.hint,
                !hint.isEmpty {
                
                self.addSubview(self.hintLabel)
                self.titleLabel.snp.remakeConstraints { (make) in
                    make.leading.equalTo(self.iconView.snp.trailing).offset(self.sideInset)
                    make.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.equalToSuperview().inset(self.topInset)
                }
                
                self.hintLabel.snp.makeConstraints { (make) in
                    make.leading.trailing.equalTo(self.titleLabel)
                    make.top.equalTo(self.titleLabel.snp.bottom).offset(self.topInset/2)
                    make.bottom.equalToSuperview().inset(self.topInset)
                }
            } else {
                self.hintLabel.removeFromSuperview()
                self.titleLabel.snp.remakeConstraints { (make) in
                    make.leading.equalTo(self.iconView.snp.trailing).offset(self.sideInset)
                    make.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.bottom.equalToSuperview().inset(self.topInset)
                }
            }
            self.setNeedsLayout()
        }
    }
}
