import UIKit

extension SendPaymentDestination {
    
    public enum EmptyCell {
        
        public struct ViewModel: CellViewModel {
            let message: String
            
            public func setup(cell: Cell) {
                cell.message = self.message
            }
        }
        
        public class Cell: UITableViewCell {
            
            // MARK: - Public properties
            
            var message: String? {
                get { return self.messageLabel.text }
                set { self.messageLabel.text = newValue }
            }
            
            // MARK: - Private properties
            
            private let messageLabel: UILabel = UILabel()
            
            // MARK: -
            
            public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
                super.init(style: style, reuseIdentifier: reuseIdentifier)
                
                self.setupView()
                self.setupMessageLabel()
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
            
            private func setupMessageLabel() {
                self.messageLabel.backgroundColor = Theme.Colors.contentBackgroundColor
                self.messageLabel.textColor = Theme.Colors.sideTextOnContainerBackgroundColor
                self.messageLabel.font = Theme.Fonts.plainTextFont
                self.messageLabel.textAlignment = .center
                self.messageLabel.numberOfLines = 0
            }
            
            private func setupLayout() {
                self.addSubview(self.messageLabel)
                
                self.messageLabel.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview().inset(20.0)
                }
            }
        }
    }
}
