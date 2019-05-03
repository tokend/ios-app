import UIKit

extension ConfirmationScene.View {
    
    class BaseCell: UITableViewCell {
        let iconSize: CGFloat = 24.0
        let sideInset: CGFloat = 20.0
        let topInset: CGFloat = 15.0
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setupView() {
            self.backgroundColor = Theme.Colors.contentBackgroundColor
            self.separatorInset = UIEdgeInsets(
                top: 0.0,
                left: self.sideInset * 2 + self.iconSize,
                bottom: 0.0,
                right: 0.0
            )
            self.selectionStyle = .none
        }
    }
}
