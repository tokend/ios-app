import UIKit

extension SendPaymentDestination {
    
    public enum ContactCell {
        
        public struct ViewModel: CellViewModel {
            
            public let name: String
            public let email: String
            
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
            private let separator: UIView = UIView()
            
            override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
                super.init(style: style, reuseIdentifier: reuseIdentifier)
                
                self.setupView()
                self.setupNameLabel()
                self.setupSeparator()
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
            
            private func setupSeparator() {
                self.separator.backgroundColor = Theme.Colors.separatorOnContentBackgroundColor
            }
            
            private func setupLayout() {
                self.contentView.addSubview(self.nameLabel)
                self.contentView.addSubview(self.separator)
                
                self.nameLabel.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(15.0)
                    make.top.bottom.equalToSuperview().inset(10.0)
                }
                
                self.separator.snp.makeConstraints { (make) in
                    make.leading.trailing.bottom.equalToSuperview()
                    make.height.equalTo(1.0/UIScreen.main.scale)
                }
            }
        }
    }
}
