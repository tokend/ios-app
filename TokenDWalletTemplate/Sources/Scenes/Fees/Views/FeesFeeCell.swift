import UIKit
import RxSwift

extension Fees {
    
    enum FeeCell {
        public struct ViewModel: CellViewModel {
            
            public let boundsValue: String
            public let fixed: String
            public let percent: String
            
            public func setup(cell: View) {
                cell.boundsValue = self.boundsValue
                cell.fixed = self.fixed
                cell.percent = self.percent
            }
        }
        
        public class View: UITableViewCell {
            
            // MARK: - Private properties
            
            private let disposeBag = DisposeBag()
            
            private let boundsLabel: UILabel = UILabel()
            private let fixedTitleLabel: UILabel = UILabel()
            private let fixedValueLabel: UILabel = UILabel()
            private let percentTitleLabel: UILabel = UILabel()
            private let percentValueLabel: UILabel = UILabel()
            
            // MARK: - Public properties
            
            public var boundsValue: String? {
                get { return self.boundsLabel.text }
                set { self.boundsLabel.text = newValue }
            }
            
            public var fixed: String? {
                get { return self.fixedValueLabel.text }
                set { self.fixedValueLabel.text = newValue }
            }
            
            public var percent: String? {
                get { return self.percentValueLabel.text }
                set { self.percentValueLabel.text = newValue }
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
                self.setupBoundsLabel()
                self.setupFixedTitleLabel()
                self.setupFixedValueLabel()
                self.setupPercentTitleLabel()
                self.setupPercentValueLabel()
                
                self.setupLayout()
            }
            
            private func setupView() {
                self.backgroundColor = Theme.Colors.contentBackgroundColor
                self.selectionStyle = .none
            }
            
            private func setupBoundsLabel() {
                self.boundsLabel.font = Theme.Fonts.plainTextFont
                self.boundsLabel.textColor = Theme.Colors.separatorOnContentBackgroundColor
            }
            
            private func setupFixedTitleLabel() {
                self.fixedTitleLabel.text = Localized(.fixed_colon)
                self.fixedTitleLabel.font = Theme.Fonts.plainTextFont
                self.fixedTitleLabel.textColor = Theme.Colors.textOnContentBackgroundColor
                self.fixedTitleLabel.textAlignment = .left
                self.fixedTitleLabel.numberOfLines = 0
                self.fixedTitleLabel.lineBreakMode = .byWordWrapping
            }
            
            private func setupFixedValueLabel() {
                self.fixedValueLabel.font = Theme.Fonts.plainTextFont
                self.fixedValueLabel.textColor = Theme.Colors.accentColor
                self.fixedValueLabel.textAlignment = .left
                self.fixedValueLabel.numberOfLines = 0
                self.fixedValueLabel.lineBreakMode = .byWordWrapping
            }
            
            private func setupPercentTitleLabel() {
                self.percentTitleLabel.text = Localized(.percent_colon)
                self.percentTitleLabel.font = Theme.Fonts.plainTextFont
                self.percentTitleLabel.textColor = Theme.Colors.textOnContentBackgroundColor
                self.percentTitleLabel.textAlignment = .left
            }
            
            private func setupPercentValueLabel() {
                self.percentValueLabel.font = Theme.Fonts.plainTextFont
                self.percentValueLabel.textColor = Theme.Colors.accentColor
                self.percentValueLabel.textAlignment = .left
            }
            
            private func setupLayout() {
                self.contentView.addSubview(self.boundsLabel)
                self.contentView.addSubview(self.fixedTitleLabel)
                self.contentView.addSubview(self.fixedValueLabel)
                self.contentView.addSubview(self.percentTitleLabel)
                self.contentView.addSubview(self.percentValueLabel)
                
                let sideInset: CGFloat = 15
                let topInset: CGFloat = 10
                let bottomInset: CGFloat = 5
                
                self.percentTitleLabel.setContentHuggingPriority(
                    .defaultHigh,
                    for: .horizontal
                )
                self.percentValueLabel.setContentHuggingPriority(
                    .defaultLow,
                    for: .horizontal
                )
                
                self.percentTitleLabel.setContentCompressionResistancePriority(
                    .defaultLow,
                    for: .horizontal
                )
                self.percentValueLabel.setContentCompressionResistancePriority(
                    .defaultHigh,
                    for: .horizontal
                )
                
                self.boundsLabel.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(sideInset)
                    make.top.equalToSuperview().inset(topInset)
                }
                self.fixedTitleLabel.snp.makeConstraints { (make) in
                    make.leading.equalToSuperview().inset(sideInset)
                    make.top.equalTo(self.boundsLabel.snp.bottom).offset(topInset)
                }
                self.fixedValueLabel.snp.makeConstraints { (make) in
                    make.leading.equalTo(self.percentValueLabel)
                    make.trailing.equalToSuperview().inset(sideInset)
                    make.centerY.equalTo(self.fixedTitleLabel)
                }
                self.percentTitleLabel.snp.makeConstraints { (make) in
                    make.leading.equalToSuperview().inset(sideInset)
                    make.top.equalTo(self.fixedTitleLabel.snp.bottom).offset(bottomInset)
                    make.bottom.equalToSuperview()
                }
                self.percentValueLabel.snp.makeConstraints { (make) in
                    make.leading.equalTo(self.percentTitleLabel.snp.trailing).offset(sideInset)
                    make.trailing.equalToSuperview().inset(sideInset)
                    make.centerY.equalTo(self.percentTitleLabel)
                    make.bottom.equalToSuperview()
                }
            }
        }
    }
}
