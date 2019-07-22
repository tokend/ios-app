import UIKit
import Nuke

public protocol BalanceHeaderDisplayLogic: class {
    typealias Event = BalanceHeader.Event
    
    func displayBalanceUpdated(viewModel: Event.BalanceUpdated.ViewModel)
}

extension BalanceHeader {
    public typealias DisplayLogic = BalanceHeaderDisplayLogic
    
    @objc(BalanceHeaderView)
    public class View: UIView {
        
        public typealias Event = BalanceHeader.Event
        public typealias Model = BalanceHeader.Model
        
        // MARK: - Private properties
        
        private let backgroundView: UIView = UIView()
        
        private let iconContainerView: UIView = UIView()
        private let iconView: UIImageView = UIImageView()
        private let abbreviationView: UIView = UIView()
        private let abbreviationLabel: UILabel = UILabel()
        
        private let labelsStackView: UIStackView = UIStackView()
        private let balanceLabel: UILabel = UILabel()
        private let rateLabel: UILabel = UILabel()
        
        private let iconSize: CGFloat = 60.0
        
        private var contentHeight: CGFloat {
            return 130
        }
        
        private var labelsStackViewCenterYMultiplier: CGFloat {
            return 0.8
        }
        
        // MARK: -
        
        var titleTextDidChange: OnTitleTextDidChangeCallback?
        var titleAlphaDidChange: OnTitleAlphaDidChangeCallback?
        
        var collapsePercentage: CGFloat = 1 {
            didSet {
                self.handleCollapseChange()
            }
        }
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        private var onDeinit: DeinitCompletion = nil
        
        public func inject(
            interactorDispatch: InteractorDispatch?,
            routing: Routing?,
            onDeinit: DeinitCompletion = nil
            ) {
            
            self.interactorDispatch = interactorDispatch
            self.routing = routing
            self.onDeinit = onDeinit
            
            self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                let request = Event.ViewDidLoad.Request()
                businessLogic.onViewDidLoad(request: request)
            })
        }
        
        // MARK: - Overridden
        
        public override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.commonInit()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - Private
        
        private func updateImageRepresentation(imageRepresenation: Model.ImageRepresentation) {
            switch imageRepresenation {
                
            case .abbreviation(let text, let color):
                self.abbreviationLabel.text = text
                self.abbreviationView.backgroundColor = color
                self.iconView.isHidden = true
                
            case .image(let url):
                self.iconView.isHidden = false
                Nuke.loadImage(with: url, into: self.iconView)
            }
        }
        
        private func commonInit() {
            self.setupView()
            self.setupBalanceLabel()
            self.setupRateLabel()
            self.setupIconContainerView()
            self.setupIconView()
            self.setupAbbreviationView()
            self.setupAbbreviationLabel()
            self.setupLabelsStackView()
            
            self.setupLayout()
        }
        
        private func setupView() {
            self.backgroundColor = UIColor.clear
        }
        
        private func setupBalanceLabel() {
            self.balanceLabel.font = Theme.Fonts.flexibleHeaderTitleFont
            self.balanceLabel.textColor = Theme.Colors.textOnMainColor
            self.balanceLabel.adjustsFontSizeToFitWidth = true
            self.balanceLabel.minimumScaleFactor = 0.1
            self.balanceLabel.numberOfLines = 1
            self.balanceLabel.textAlignment = .center
        }
        
        private func setupRateLabel() {
            self.rateLabel.font = Theme.Fonts.plainTextFont
            self.rateLabel.textColor = Theme.Colors.textOnMainColor
            self.rateLabel.adjustsFontSizeToFitWidth = true
            self.rateLabel.minimumScaleFactor = 0.1
            self.rateLabel.numberOfLines = 1
            self.rateLabel.textAlignment = .center
        }
        
        private func setupIconContainerView() {
            self.iconContainerView.layer.cornerRadius = self.iconSize / 2
        }
        
        private func setupIconView() {
            self.iconView.layer.cornerRadius = self.iconSize / 2
            self.iconView.layer.masksToBounds = true
            self.iconView.contentMode = .scaleAspectFit
        }
        
        private func setupAbbreviationView() {
            self.abbreviationView.layer.cornerRadius = self.iconSize / 2
        }
        
        private func setupAbbreviationLabel() {
            self.abbreviationLabel.layer.cornerRadius = self.iconSize / 2
            self.abbreviationLabel.textColor = Theme.Colors.textOnAccentColor
            self.abbreviationLabel.font = Theme.Fonts.hugeTitleFont
            self.abbreviationLabel.textAlignment = .center
        }
        
        private func setupLabelsStackView() {
            self.labelsStackView.backgroundColor = Theme.Colors.mainColor
            self.labelsStackView.alignment = .center
            self.labelsStackView.axis = .vertical
            self.labelsStackView.distribution = .fill
        }
        
        private func setupLayout() {
            self.addSubview(self.iconContainerView)
            self.addSubview(self.balanceLabel)
            self.addSubview(self.rateLabel)
            
            self.abbreviationView.addSubview(self.abbreviationLabel)
            self.iconContainerView.addSubview(self.abbreviationView)
            self.iconContainerView.addSubview(self.iconView)
            
            self.iconContainerView.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview()
                make.height.width.equalTo(self.iconSize)
            }
            
            self.abbreviationView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            self.abbreviationLabel.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            self.iconView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            
            self.balanceLabel.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(self.iconContainerView.snp.bottom).offset(10.0)
            }
            
            self.rateLabel.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(self.balanceLabel.snp.bottom).offset(5.0)
            }
        }
        
        private func setRate(_ rate: String?) {
            self.rateLabel.text = rate
        }
        
        private func handleCollapseChange() {
            let percent = self.collapsePercentage
            
            let balanceLabelDisappearPercent: CGFloat = 0.65
            let balanceLabelAppearPercent: CGFloat = 0.90
            let currentDisappearDiff = percent - balanceLabelDisappearPercent
            let appearDisappearDiff = balanceLabelAppearPercent - balanceLabelDisappearPercent
            self.balanceLabel.alpha = max((currentDisappearDiff) / (appearDisappearDiff), 0)
            
            let rateLabelDisappearPercent: CGFloat = 0.75
            let rateLabelPercentPercent: CGFloat = 0.95
            let currentDisappearRateDiff = percent - rateLabelDisappearPercent
            let appearDisappearRateDiff = rateLabelPercentPercent - rateLabelDisappearPercent
            self.rateLabel.alpha = max((currentDisappearRateDiff) / (appearDisappearRateDiff), 0)
            
            let iconLabelDisappearPercent: CGFloat = 0.25
            let iconLabelPercentPercent: CGFloat = 0.75
            let currentDisappearIconDiff = percent - iconLabelDisappearPercent
            let appearDisappearIconDiff = iconLabelPercentPercent - iconLabelDisappearPercent
            self.iconContainerView.alpha = max((currentDisappearIconDiff) / (appearDisappearIconDiff), 0)
            
            let navigationTitleFontSize = Theme.Fonts.navigationBarBoldFont.pointSize
            let balanceFontSize = self.balanceLabel.font.pointSize
            let fontsDelta = balanceFontSize - navigationTitleFontSize
            let scalePercent = (navigationTitleFontSize + fontsDelta * percent) / balanceFontSize
            self.labelsStackView.transform = CGAffineTransform.identity.scaledBy(x: scalePercent, y: scalePercent)
            self.titleAlphaDidChange?((balanceLabelDisappearPercent - percent) / balanceLabelDisappearPercent)
        }
    }
}

extension BalanceHeader.View: BalanceHeader.DisplayLogic {
    
    public func displayBalanceUpdated(viewModel: Event.BalanceUpdated.ViewModel) {
        self.balanceLabel.text = viewModel.balance
        self.rateLabel.text = viewModel.rate
        self.titleTextDidChange?(viewModel.balance)
        self.updateImageRepresentation(imageRepresenation: viewModel.imageRepresentation)
    }
}

extension BalanceHeader.View: FlexibleHeaderContainerHeaderViewProtocol {
    
    var view: UIView {
        return self
    }
    
    var minimumHeight: CGFloat {
        return 0.0
    }
    
    var maximumHeight: CGFloat {
        return self.minimumHeight + self.contentHeight
    }
}
