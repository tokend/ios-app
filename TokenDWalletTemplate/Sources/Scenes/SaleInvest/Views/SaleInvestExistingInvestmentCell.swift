import UIKit

extension SaleInvest {
    
    public enum ExistingInvestmentCell {
        
        public struct ViewModel: CellViewModel {
            let investmentAmount: String
            
            public func setup(cell: View) {
                cell.amount = self.investmentAmount
            }
        }
        
        public class View: UITableViewCell {
            
            // MARK: - Public properties
            
            var amount: String? {
                get { return self.amountLabel.text }
                set { self.amountLabel.text = newValue }
            }
            
            // MARK: - Private properties
            
            private let amountLabel: UILabel = UILabel()
            
            private let topInset: CGFloat = 10.0
            
            // MARK: -
            
            public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
                super.init(style: style, reuseIdentifier: reuseIdentifier)
                
                self.setupView()
                self.setupAmountLabel()
                self.setupLayout()
            }
            
            required init?(coder aDecoder: NSCoder) {
                super.init(coder: aDecoder)
                
                self.setupView()
                self.setupAmountLabel()
                self.setupLayout()
            }
            
            // MARK: - Private
            
            private func setupView() {
                self.backgroundColor = Theme.Colors.contentBackgroundColor
                self.selectionStyle = .none
            }
            
            private func setupAmountLabel() {
                self.amountLabel.backgroundColor = Theme.Colors.contentBackgroundColor
                self.amountLabel.textColor = Theme.Colors.separatorOnMainColor
                self.amountLabel.font = Theme.Fonts.smallTextFont
                self.amountLabel.textAlignment = .center
            }
            
            private func setupLayout() {
                self.addSubview(self.amountLabel)
                
                self.amountLabel.snp.makeConstraints { (make) in
                    make.centerX.equalToSuperview()
                    make.top.equalToSuperview().inset(self.topInset)
                    make.bottom.equalToSuperview()
                }
            }
        }
    }
    
}
