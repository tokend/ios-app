import RxCocoa
import RxSwift
import SnapKit
import UIKit

enum SettingsLoadingCell {
    struct Model: CellViewModel {
        
        let title: String
        let identifier: Settings.CellIdentifier
        let icon: UIImage
        
        func setup(cell: SettingsLoadingCell.View) {
            
            cell.title = self.title
            cell.icon = self.icon
        }
    }
    
    class View: UITableViewCell {
        
        // MARK: - Closures
        
        typealias OnDidSwitch = (Bool) -> Void
        
        // MARK: - Private properties
        
        private let disposeBag = DisposeBag()
        
        private let titleLabel: UILabel = UILabel()
        private let iconImageView: UIImageView = UIImageView()
        private let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .gray)
        
        // MARK: - Public properties
        
        public var title: String? {
            get { return self.titleLabel.text }
            set { self.titleLabel.text = newValue }
        }
        public var icon: UIImage? {
            get { return self.iconImageView.image }
            set { self.iconImageView.image = newValue }
        }
        
        // MARK: - Initializers
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            self.commonInit()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - Private
        
        private func commonInit() {
            self.setupLoadingIndicator()
            self.setupView()
            self.setupTitleLabel()
            self.setupIconImageView()
            
            self.setupLayout()
        }
        
        private func setupLoadingIndicator() {
            self.loadingIndicator.hidesWhenStopped = true
            self.loadingIndicator.startAnimating()
        }
        
        private func setupView() {
            self.backgroundColor = Theme.Colors.contentBackgroundColor
            self.selectionStyle = .none
        }
        
        private func setupTitleLabel() {
            self.titleLabel.font = Theme.Fonts.plainTextFont
            self.titleLabel.textColor = Theme.Colors.textOnContentBackgroundColor
            self.titleLabel.textAlignment = .left
            self.titleLabel.numberOfLines = 0
            self.titleLabel.lineBreakMode = .byWordWrapping
        }
        
        private func setupIconImageView() {
            self.iconImageView.tintColor = Theme.Colors.iconColor
            self.iconImageView.clipsToBounds = true
            self.iconImageView.contentMode = .scaleAspectFit
        }
        
        private func setupLayout() {
            self.contentView.addSubview(self.iconImageView)
            self.contentView.addSubview(self.loadingIndicator)
            self.contentView.addSubview(self.titleLabel)
            
            let sideInset: CGFloat = 15
            let sideInsetSwitch: CGFloat = 20
            let topInset: CGFloat = 14
            let bottomInset: CGFloat = 14
            let expectedIconWidth: CGFloat = 24
            let actualIconWidth: CGFloat = 18
            let iconWidthDelta: CGFloat = expectedIconWidth - actualIconWidth
            
            self.iconImageView.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.leading.equalToSuperview().inset(sideInset + iconWidthDelta / 2)
                make.width.height.equalTo(actualIconWidth)
            }
            
            self.loadingIndicator.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview().inset(sideInsetSwitch)
            }
            
            self.titleLabel.snp.makeConstraints { (make) in
                make.top.equalToSuperview().inset(topInset)
                make.bottom.equalToSuperview().inset(bottomInset)
                make.trailing.equalTo(self.loadingIndicator.snp.leading).offset(-sideInset)
                make.leading.equalTo(self.iconImageView.snp.trailing).offset(sideInset)
            }
        }
    }
}
