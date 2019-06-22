import UIKit
import Nuke

extension AssetPicker {
    
    public enum AssetCell {
        
        public struct ViewModel: CellViewModel {
            let code: String
            let imageRepresentation: AssetPicker.Model.ImageRepresentation
            let abbreviationBackgroundColor: UIColor
            let abbreviationText: String
            let ownerAccountId: String
            
            public func setup(cell: Cell) {
                cell.code = self.code
                cell.imageRepresentation = imageRepresentation
                cell.abbreviationBackgroundColor = self.abbreviationBackgroundColor
                cell.abbreviationText = self.abbreviationText
            }
        }
        
        public class Cell: UITableViewCell {
            
            // MARK: - Public properties
            
            var code: String? {
                get { return self.codeLabel.text }
                set { self.codeLabel.text = newValue }
            }
            
            var imageRepresentation: AssetPicker.Model.ImageRepresentation? {
                didSet {
                    self.updateImage()
                }
            }
            
            var abbreviationBackgroundColor: UIColor? {
                get { return self.abbreviationView.backgroundColor }
                set { self.abbreviationView.backgroundColor = newValue }
            }
            
            var abbreviationText: String? {
                get { return self.abbreviationLabel.text }
                set { self.abbreviationLabel.text = newValue }
            }
            
            // MARK: - Private properties
            
            private let nameLabel: UILabel = UILabel()
            private let codeLabel: UILabel = UILabel()
            
            private let iconView: UIImageView = UIImageView()
            private let abbreviationView: UIView = UIView()
            private let abbreviationLabel: UILabel = UILabel()
            
            private let sideInset: CGFloat = 20.0
            private let topInset: CGFloat = 15.0
            private let iconSize: CGFloat = 60.0
            
            // MARK: -
            
            override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
                super.init(style: style, reuseIdentifier: reuseIdentifier)
                
                self.setupView()
                self.setupNameLabel()
                self.setupIconView()
                self.setupAbbreviationView()
                self.setupAbbreviationLabel()
                self.setupLayout()   
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            // MARK: - Private
            
            private func updateImage() {
                guard let imageRepresentation = self.imageRepresentation else {
                    return
                }
                switch imageRepresentation {
                    
                case .abbreviation:
                    self.iconView.isHidden = true
                    
                case .image(let url):
                    self.iconView.isHidden = false
                    Nuke.loadImage(with: url, into: self.iconView)
                }
            }
            
            private func setupView() {
                self.backgroundColor = Theme.Colors.contentBackgroundColor
                self.selectionStyle = .none
            }
            
            private func setupNameLabel() {
                self.nameLabel.backgroundColor = Theme.Colors.contentBackgroundColor
                self.nameLabel.font = Theme.Fonts.plainTextFont
            }
            
            private func setupIconView() {
                self.iconView.backgroundColor = Theme.Colors.contentBackgroundColor
                self.iconView.layer.cornerRadius = self.iconSize / 2
                self.iconView.layer.masksToBounds = true
                self.iconView.contentMode = .scaleAspectFit
            }
            
            private func setupAbbreviationView() {
                self.abbreviationView.layer.cornerRadius = self.iconSize / 2
            }
            
            private func setupAbbreviationLabel() {
                self.abbreviationLabel.textColor = Theme.Colors.textOnAccentColor
                self.abbreviationLabel.font = Theme.Fonts.hugeTitleFont
                self.abbreviationLabel.textAlignment = .center
            }
            
            private func setupLayout() {
                self.addSubview(self.abbreviationView)
                self.abbreviationView.addSubview(self.abbreviationLabel)
                self.addSubview(self.iconView)
                self.addSubview(self.codeLabel)
                
                self.abbreviationView.snp.makeConstraints { (make) in
                    make.leading.equalToSuperview().inset(self.sideInset)
                    make.top.bottom.equalToSuperview().inset(self.topInset)
                    make.height.width.equalTo(self.iconSize)
                }
                
                self.abbreviationLabel.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
                
                self.iconView.snp.makeConstraints { (make) in
                    make.edges.equalTo(self.abbreviationView)
                }
                
                self.codeLabel.snp.makeConstraints { (make) in
                    make.leading.equalTo(self.abbreviationView.snp.trailing).offset(self.sideInset)
                    make.trailing.equalToSuperview().inset(self.sideInset)
                    make.centerY.equalTo(self.abbreviationView.snp.centerY)
                }
            }
        }
    }
}
