import UIKit

extension BalancesList {
    
    public enum LegendCell {
        
        public struct ViewModel: CellViewModel {
            let assetName: String
            let balance: String
            let isSelected: Bool
            let indicatorColor: UIColor
            let percentageValue: Double
            
            public func setup(cell: View) {
                cell.assetName = self.assetName
                cell.balance = self.balance
                cell.isBalanceSelected = self.isSelected
                cell.indicatorColor = self.indicatorColor
            }
        }
        
        public class View: UITableViewCell {
            
            // MARK: - Public properties
            
            var assetName: String? {
                get { return self.assetNameLabel.text }
                set { self.assetNameLabel.text = newValue }
            }
            
            var balance: String? {
                get { return self.balanceLabel.text }
                set { self.balanceLabel.text = newValue }
            }
            
            var isBalanceSelected: Bool = false {
                didSet {
                    self.updateIndicator()
                }
            }
            
            var indicatorColor: UIColor = Theme.Colors.contentBackgroundColor {
                didSet {
                    self.updateIndicator()
                }
            }
            
            // MARK: - Private properties
            
            private let assetNameLabel: UILabel = UILabel()
            private let balanceLabel: UILabel = UILabel()
            private let indicatorView: UIView = UIView()
            
            private let indicatorSize: CGFloat = 10.0
            private let sideInset: CGFloat = 10.0
            private let topInset: CGFloat = 5.0
            
            // MARK: -
            
            public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
                super.init(style: style, reuseIdentifier: reuseIdentifier)
                
                self.setupView()
                self.setupAssetNameLabel()
                self.setupBalanceLabel()
                self.setupIndicatorView()
                self.setupLayout()
            }
            
            required init?(coder aDecoder: NSCoder) {
                super.init(coder: aDecoder)
                
                self.setupView()
                self.setupAssetNameLabel()
                self.setupBalanceLabel()
                self.setupIndicatorView()
                self.setupLayout()
            }
            
            // MARK: - Private
            
            private func updateIndicator() {
                self.indicatorView.layer.borderColor = self.indicatorColor.cgColor
                if self.isBalanceSelected {
                    self.indicatorView.backgroundColor = self.indicatorColor
                } else {
                    self.indicatorView.backgroundColor = Theme.Colors.contentBackgroundColor
                }
            }
            
            // MARK: - Setup
            
            private func setupView() {
                self.backgroundColor = Theme.Colors.contentBackgroundColor
                self.selectionStyle = .none
            }
            
            private func setupAssetNameLabel() {
                self.assetNameLabel.backgroundColor = Theme.Colors.contentBackgroundColor
                self.assetNameLabel.numberOfLines = 1
                self.assetNameLabel.lineBreakMode = .byTruncatingMiddle
            }
            
            private func setupBalanceLabel() {
                self.balanceLabel.backgroundColor = Theme.Colors.contentBackgroundColor
                self.balanceLabel.textColor = Theme.Colors.separatorOnMainColor
                self.balanceLabel.font = Theme.Fonts.smallTextFont
            }
            
            private func setupIndicatorView() {
                self.indicatorView.layer.cornerRadius = self.indicatorSize / 2
                self.indicatorView.layer.borderWidth = 2.0
            }
            
            private func setupLayout() {
                self.addSubview(self.indicatorView)
                self.addSubview(self.assetNameLabel)
                self.addSubview(self.balanceLabel)
                
                self.indicatorView.snp.makeConstraints { (make) in
                    make.leading.equalToSuperview().inset(self.sideInset)
                    make.centerY.equalToSuperview()
                    make.height.width.equalTo(self.indicatorSize)
                }
                
                self.assetNameLabel.snp.makeConstraints { (make) in
                    make.leading.equalTo(self.indicatorView.snp.trailing).offset(self.sideInset)
                    make.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.equalToSuperview().inset(self.topInset)
                    make.bottom.equalTo(self.indicatorView.snp.centerY)
                }
                
                self.balanceLabel.snp.makeConstraints { (make) in
                    make.leading.equalTo(self.indicatorView.snp.trailing).offset(self.sideInset)
                    make.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.equalTo(self.indicatorView.snp.centerY)
                    make.bottom.equalToSuperview().inset(self.topInset)
                }
            }
        }
    }
}
