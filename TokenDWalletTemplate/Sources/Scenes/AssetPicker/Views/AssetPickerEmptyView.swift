import UIKit

extension AssetPicker {
    
    class EmptyView: UIView {
        
        // MARK: - Private properties
        
        private let messageLabel: UILabel = UILabel()
        
        // MARK: -
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.setupView()
            self.setupMessageLabel()
            self.setupLayout()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.backgroundColor = Theme.Colors.containerBackgroundColor
        }
        
        private func setupMessageLabel() {
            self.messageLabel.text = Localized(.available_assets_for_this_operations)
            self.messageLabel.textAlignment = .center
            self.messageLabel.textColor = Theme.Colors.textFieldForegroundDisabledColor
            self.messageLabel.font = Theme.Fonts.smallTextFont
            self.messageLabel.numberOfLines = 0
        }
        
        private func setupLayout() {
            self.addSubview(self.messageLabel)
            
            self.messageLabel.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(20.0)
                make.centerY.equalToSuperview()
            }
        }
    }
}
