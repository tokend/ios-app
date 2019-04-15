import UIKit

extension TradeOffers {
    
    public class TitleView: UIView {
        
        // MARK: - Public properties
        
        public var title: String? {
            get { return self.titleLabel.text }
            set { self.titleLabel.text = newValue }
        }
        
        public var subTitle: String? {
            get { return self.subTitleLabel.text }
            set { self.subTitleLabel.text = newValue }
        }
        
        // MARK: - Private properties
        
        private let titleLabel: UILabel = UILabel()
        private let subTitleLabel: UILabel = UILabel()
        
        // MARK: -
        
        public override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.customInit()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            
            self.customInit()
        }
        
        private func customInit() {
            self.setupView()
            self.setupTitleLabel()
            self.setupSubTitleLabel()
            self.setupLayout()
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.backgroundColor = UIColor.clear
        }
        
        private func setupTitleLabel() {
            self.titleLabel.textColor = Theme.Colors.textOnMainColor
            self.titleLabel.textAlignment = .center
            self.titleLabel.font = Theme.Fonts.plainTextFont
        }
        
        private func setupSubTitleLabel() {
            self.subTitleLabel.textColor = Theme.Colors.textOnMainColor
            self.subTitleLabel.textAlignment = .center
            self.subTitleLabel.font = Theme.Fonts.smallTextFont
        }
        
        private func setupLayout() {
            self.addSubview(self.titleLabel)
            self.addSubview(self.subTitleLabel)
            
            self.titleLabel.snp.makeConstraints { (make) in
                make.leading.trailing.top.equalToSuperview()
            }
            
            self.subTitleLabel.snp.makeConstraints { (make) in
                make.leading.trailing.bottom.equalToSuperview()
                make.top.equalTo(self.titleLabel.snp.bottom)
            }
        }
    }
}
