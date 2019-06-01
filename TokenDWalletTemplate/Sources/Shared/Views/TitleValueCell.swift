import RxCocoa
import RxSwift
import SnapKit
import UIKit

public enum TitleValueTableViewCell {
    
    public typealias CellIdentifier = TransactionDetails.CellIdentifier
    
    public struct Model: CellViewModel {
        
        public let title: String
        public let identifier: CellIdentifier
        public let value: String
        
        public func setup(cell: TitleValueTableViewCell.View) {
            cell.title = self.title
            cell.value = self.value
        }
    }
    
    public class View: UITableViewCell {
        
        // MARK: - Private properties
        
        private let disposeBag = DisposeBag()
        
        private let titleLabel: UILabel = UILabel()
        private let valueLabel: UILabel = UILabel()
        
        // MARK: - Public properties
        
        public var title: String? {
            get { return self.titleLabel.text }
            set { self.titleLabel.text = newValue }
        }
        
        public var value: String? {
            get { return self.valueLabel.text }
            set { self.valueLabel.text = newValue }
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
            self.setupView()
            self.setupTitleLabel()
            self.setupValueLabel()
            
            self.setupLayout()
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
        
        private func setupValueLabel() {
            self.valueLabel.font = Theme.Fonts.plainTextFont
            self.valueLabel.textColor = Theme.Colors.textOnContentBackgroundColor
            self.valueLabel.textAlignment = .right
            self.valueLabel.numberOfLines = 0
            self.valueLabel.lineBreakMode = .byWordWrapping
        }
        
        private func setupLayout() {
            self.contentView.addSubview(self.titleLabel)
            self.contentView.addSubview(self.valueLabel)
            
            let sideInset: CGFloat = 15
            let topInset: CGFloat = 5.0
            let bottomInset: CGFloat = 5.0
            
            self.titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            self.valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            
            self.titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            self.valueLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
            
            self.titleLabel.snp.makeConstraints { (make) in
                make.leading.equalToSuperview().inset(sideInset)
                make.top.equalToSuperview().inset(topInset)
                make.bottom.equalToSuperview().inset(bottomInset)
            }
            self.valueLabel.snp.makeConstraints { (make) in
                make.top.equalToSuperview().inset(topInset)
                make.bottom.equalToSuperview().inset(bottomInset)
                make.trailing.equalToSuperview().inset(sideInset)
                make.leading.equalTo(self.titleLabel.snp.trailing).offset(sideInset)
            }
        }
    }
}
