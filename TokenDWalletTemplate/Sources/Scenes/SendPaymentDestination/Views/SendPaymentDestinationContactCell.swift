import UIKit

extension SendPaymentDestination {
    
    public enum ContactCell {
        
        public struct ViewModel: CellViewModel {
            let name: String
            let email: String
            
            public func setup(cell: View) {
                cell.name = self.name
            }
        }
        
        public class View: UITableViewCell {
            
            // MARK: - Public properties
            
            public var name: String? {
                get { return self.nameLabel.text }
                set { return self.nameLabel.text = newValue }
            }
            
            // MARK: - Private properties
            
            private let nameLabel: UILabel = UILabel()
            
            override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
                super.init(style: style, reuseIdentifier: reuseIdentifier)
                
                self.setupView()
                self.setupNameLabel()
                self.setupLayout()
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            // MARK: - Private
            
            private func setupView() {
                self.backgroundColor = Theme.Colors.contentBackgroundColor
            }
            
            private func setupNameLabel() {
                self.nameLabel.backgroundColor = Theme.Colors.contentBackgroundColor
                self.nameLabel.font = Theme.Fonts.plainTextFont
            }
            
            private func setupLayout() {
                self.contentView.addSubview(self.nameLabel)
                
                self.nameLabel.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(15.0)
                    make.top.bottom.equalToSuperview().inset(10.0)
                }
            }
        }
    }
}
