import UIKit

extension BalancesList {
    
    public enum HeaderCell {
        
        public struct ViewModel: CellViewModel {
            let balance: String
            let cellIdentifier: Model.CellIdentifier
            
            public func setup(cell: Cell) {
                cell.balance = self.balance
            }
        }
        
        public class Cell: UITableViewCell {
            
            // MARK: - Public properties
            
            var balance: String? {
                get { return self.balanceLabel.text }
                set { self.balanceLabel.text = newValue }
            }
            
            var cellIdentifier: Model.CellIdentifier?
            
            // MARK: - Private properties
            
            private let balanceLabel: UILabel = UILabel()
            
            private let sideInset: CGFloat = 15.0
            
            // MARK: -
            
            override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
                super.init(style: style, reuseIdentifier: reuseIdentifier)
                
                self.setupView()
                self.setupBalanceLabel()
                self.setupLayout()
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            // MARK: - Private
            
            private func setupView() {
                self.backgroundColor = Theme.Colors.contentBackgroundColor
                self.selectionStyle = .none
            }
            
            private func setupBalanceLabel() {
                self.balanceLabel.backgroundColor = Theme.Colors.contentBackgroundColor
                self.balanceLabel.font = Theme.Fonts.largeAssetFont
                self.balanceLabel.numberOfLines = 0
                self.balanceLabel.textAlignment = .center
            }
            
            private func setupLayout() {
                self.addSubview(self.balanceLabel)
                
                self.balanceLabel.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.bottom.equalToSuperview()
                }
            }
        }
    }
}
