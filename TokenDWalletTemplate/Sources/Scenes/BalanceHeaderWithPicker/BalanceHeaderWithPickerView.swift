import UIKit

protocol BalanceHeaderWithPickerDisplayLogic: class {
    typealias Event = BalanceHeaderWithPicker.Event
    
    func displayBalancesDidChange(viewModel: Event.BalancesDidChange.ViewModel)
    func displaySelectedBalanceDidChange(viewModel: Event.SelectedBalanceDidChange.ViewModel)
}

extension BalanceHeaderWithPicker {
    typealias DisplayLogic = BalanceHeaderWithPickerDisplayLogic
    
    class View: UIView {
        
        typealias Event = BalanceHeaderWithPicker.Event
        typealias Model = BalanceHeaderWithPicker.Model
        
        // MARK: - Private properties
        
        private let backgroundView: UIView = UIView()
        private let labelsStackView: UIStackView = UIStackView()
        private let balanceLabel: UILabel = UILabel()
        private let rateLabel: UILabel = UILabel()
        
        private let balancePicker: HorizontalPicker = HorizontalPicker()
        
        private var pickerHeight: CGFloat {
            return 50.0
        }
        
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
        
        func inject(interactorDispatch: InteractorDispatch?, routing: Routing?) {
            self.interactorDispatch = interactorDispatch
            self.routing = routing
            
            self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                let request = Event.DidInjectModules.Request()
                businessLogic.onDidInjectModules(request)
            })
        }
        
        // MARK: -
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.commonInit()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - Private
        
        private func commonInit() {
            self.setupView()
            self.setupBalanceLabel()
            self.setupRateLabel()
            self.setupBackgroundView()
            self.setupLabelsStackView()
            self.setupBalancePicker()
            
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
        
        private func setupBackgroundView() {
            self.backgroundView.backgroundColor = Theme.Colors.mainColor
        }
        
        private func setupLabelsStackView() {
            self.labelsStackView.alignment = .center
            self.labelsStackView.axis = .vertical
            self.labelsStackView.distribution = .fill
            self.labelsStackView.spacing = 4
        }
        
        private func setupBalancePicker() {
            self.balancePicker.backgroundColor = Theme.Colors.mainColor
            self.balancePicker.tintColor = Theme.Colors.darkAccentColor
        }
        
        private func setupLayout() {
            self.addSubview(self.backgroundView)
            self.addSubview(self.balancePicker)
            self.backgroundView.addSubview(self.labelsStackView)
            self.labelsStackView.addArrangedSubview(self.balanceLabel)
            self.labelsStackView.addArrangedSubview(self.rateLabel)
            
            self.backgroundView.snp.remakeConstraints { (make) in
                make.top.leading.trailing.equalToSuperview()
            }
            self.balancePicker.snp.makeConstraints { (make) in
                make.bottom.leading.trailing.equalToSuperview()
                make.top.equalTo(self.backgroundView.snp.bottom)
            }
            self.labelsStackView.snp.remakeConstraints { (make) in
                make.centerY.equalToSuperview().multipliedBy(self.labelsStackViewCenterYMultiplier)
                make.leading.trailing.equalToSuperview().inset(15)
            }
        }
        
        private func setRate(_ rate: String?) {
            self.rateLabel.text = rate
        }
        
        private func handleCollapseChange() {
            let percent = self.collapsePercentage
            
            let balanceLabelDisappearPercent: CGFloat = 0.37
            let balanceLabelAppearPercent: CGFloat = 0.67
            let currentDisappearDiff = percent - balanceLabelDisappearPercent
            let appearDisappearDiff = balanceLabelAppearPercent - balanceLabelDisappearPercent
            self.balanceLabel.alpha = max((currentDisappearDiff) / (appearDisappearDiff), 0)
            
            let rateLabelDisappearPercent: CGFloat = 0.65
            let rateLabelPercentPercent: CGFloat = 0.95
            let currentDisappearRateDiff = percent - rateLabelDisappearPercent
            let appearDisappearRateDiff = rateLabelPercentPercent - rateLabelDisappearPercent
            self.rateLabel.alpha = max((currentDisappearRateDiff) / (appearDisappearRateDiff), 0)
            
            let navigationTitleFontSize = Theme.Fonts.navigationBarBoldFont.pointSize
            let balanceFontSize = self.balanceLabel.font.pointSize
            let fontsDelta = balanceFontSize - navigationTitleFontSize
            let scalePercent = (navigationTitleFontSize + fontsDelta * percent) / balanceFontSize
            self.labelsStackView.transform = CGAffineTransform.identity.scaledBy(x: scalePercent, y: scalePercent)
            self.titleAlphaDidChange?((balanceLabelDisappearPercent - percent) / balanceLabelDisappearPercent)
        }
        
        private func setSelectedBalanceIfNeeded(index: Int?) {
            guard let index = index else {
                return
            }
            
            self.balancePicker.setSelectedItemAtIndex(index, animated: true)
        }
    }
}

// MARK: - BalanceHeaderWithPickerDisplayLogic

extension BalanceHeaderWithPicker.View: BalanceHeaderWithPicker.DisplayLogic {
    
    func displayBalancesDidChange(viewModel: Event.BalancesDidChange.ViewModel) {
        let items = viewModel.balances.map { (balance) -> HorizontalPicker.Item in
            return HorizontalPicker.Item(
                title: balance.name,
                enabled: balance.id != nil,
                onSelect: { [weak self] in
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        guard let id = balance.id else {
                            return
                        }
                        let request = Event.SelectedBalanceDidChange.Request(id: id)
                        businessLogic.onSelectedBalanceDidChange(request)
                    })
            })
        }
        self.balancePicker.items = items
        self.setSelectedBalanceIfNeeded(index: viewModel.selectedBalanceIndex)
    }
    
    func displaySelectedBalanceDidChange(viewModel: Event.SelectedBalanceDidChange.ViewModel) {
        self.balanceLabel.text = viewModel.balance
        self.rateLabel.text = viewModel.rate
        
        self.routing?.onDidSelectBalance(viewModel.id, viewModel.asset)
    }
}

// MARK: - FlexibleHeaderContainerHeaderViewProtocol

extension BalanceHeaderWithPicker.View: FlexibleHeaderContainerHeaderViewProtocol {
    
    var view: UIView {
        return self
    }
    
    var minimumHeight: CGFloat {
        return self.pickerHeight
    }
    
    var maximumHeight: CGFloat {
        return self.minimumHeight + self.contentHeight
    }
}
