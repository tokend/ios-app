import UIKit
import SnapKit

enum SideMenuTableViewCell {
    struct Model: CellViewModel {
        
        typealias OnClickCallback = (() -> Void)
        
        let icon: UIImage?
        let title: String
        let onClick: OnClickCallback?
        
        func setup(cell: View) {
            cell.icon = self.icon
            cell.title = self.title
        }
    }
    
    class View: UITableViewCell {
        
        // MARK: - Closures
        
        typealias OnActionButtonClicked = (View) -> Void
        
        // MARK: - Private properties
        
        private let iconView: UIImageView = UIImageView()
        private let titleLabel: UILabel = UILabel()
        
        // MARK: - Public properties
        
        public var icon: UIImage? {
            get { return self.iconView.image }
            set { self.iconView.image = newValue }
        }
        public var title: String? {
            get { return self.titleLabel.text }
            set { self.titleLabel.text = newValue }
        }
        
        // MARK: - Overridden methods
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            self.commonInit()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - Private
        
        private func commonInit() {
            self.setupView()
            self.setupIconView()
            self.setupTitleLabel()
            
            self.setupLayout()
        }
        
        private func setupView() {
            self.backgroundColor = Theme.Colors.contentBackgroundColor
            self.selectionStyle = .gray
        }
        
        private func setupIconView() {
            self.iconView.contentMode = .scaleAspectFit
            self.iconView.tintColor = Theme.Colors.iconOnSideMenuBackgroundColor
        }
        
        private func setupTitleLabel() {
            self.titleLabel.textAlignment = .left
            self.titleLabel.textColor = Theme.Colors.textOnSideMenuBackgroundColor
            self.titleLabel.font = Theme.Fonts.menuCellTextFont
            self.titleLabel.numberOfLines = 1
            self.titleLabel.setContentHuggingPriority(.required, for: .vertical)
            self.titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            self.titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        
        private func setupLayout() {
            self.contentView.addSubview(self.iconView)
            self.contentView.addSubview(self.titleLabel)
            
            let sideInset: CGFloat = 15
            let topInset: CGFloat = 14
            let bottomInset: CGFloat = 14
            let expectedIconWidth: CGFloat = 24
            let actualIconWidth: CGFloat = 20
            let iconWidthDelta: CGFloat = expectedIconWidth - actualIconWidth
            
            self.iconView.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.leading.equalToSuperview().inset(sideInset + iconWidthDelta / 2)
                make.width.height.equalTo(actualIconWidth)
            }
            
            self.titleLabel.snp.makeConstraints { (make) in
                make.top.equalToSuperview().inset(topInset)
                make.bottom.equalToSuperview().inset(bottomInset)
                make.trailing.equalToSuperview().inset(sideInset)
                make.leading.equalTo(self.iconView.snp.trailing).offset(sideInset + iconWidthDelta / 2)
            }
        }
    }
}
