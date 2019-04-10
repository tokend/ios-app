import UIKit

extension TradesList {
    
    public class AssetPairListView: UIView {
        
        // MARK: - Public properties
        
        public var logoLetter: String? {
            get { return self.logoLetterLabel.text }
            set { self.logoLetterLabel.text = newValue }
        }
        
        public var logoColoring: UIColor? {
            get { return self.logoLetterLabel.backgroundColor }
            set { self.logoLetterLabel.backgroundColor = newValue }
        }
        
        public var title: NSAttributedString? {
            get { return self.titleLabel.attributedText }
            set { self.titleLabel.attributedText = newValue }
        }
        
        public var subTitle: String? {
            get { return self.subTitleLabel.text }
            set { self.subTitleLabel.text = newValue }
        }
        
        public var id: PairID = ""
        
        // MARK: - Private properties
        
        private let logoLetterLabel: UILabel = UILabel()
        private let titleLabel: UILabel = UILabel()
        private let subTitleLabel: UILabel = UILabel()
        
        // MARK: -
        
        public override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.setupView()
            self.setupLogoLetterLabel()
            self.setupTitleLabel()
            self.setupSubTitleLabel()
            self.setupLayout()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - Private
        
        private func setupView() {
            
        }
        
        private func setupLogoLetterLabel() {
            
        }
        
        private func setupTitleLabel() {
            
        }
        
        private func setupSubTitleLabel() {
            
        }
        
        private func setupLayout() {
            
        }
    }
}
