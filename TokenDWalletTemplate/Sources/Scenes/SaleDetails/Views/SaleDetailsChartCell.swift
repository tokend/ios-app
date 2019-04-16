import UIKit
import Charts

extension SaleDetails {
    
    enum ChartTab {
        
        struct ViewModel {
            
            let title: String
            let subTitle: String
            
            let datePickerItems: [Model.PeriodViewModel]
            let selectedDatePickerItemIndex: Int
            
            let growth: String
            let growthPositive: Bool?
            let growthSinceDate: String
            
            let axisFormatters: Model.AxisFormatters
            let chartViewModel: Model.ChartViewModel
            
            let identifier: TabIdentifier
            
            // MARK: -
            
            func setup(tab: ChartTab.View) {
                tab.title = self.title
                tab.subTitle = self.subTitle
                
                weak var weakTab = tab
                tab.datePickerItems = self.datePickerItems.map({ (period) -> HorizontalPicker.Item in
                    return HorizontalPicker.Item(
                        title: period.title,
                        enabled: period.isEnabled,
                        onSelect: {
                            weakTab?.didSelectPickerItem?(period.period.rawValue)
                    })
                })
                tab.selectedDatePickerItemIndex = self.selectedDatePickerItemIndex
                
                tab.growth = self.growth
                tab.growthPositive = self.growthPositive
                tab.growthSinceDate = self.growthSinceDate
                tab.setAxisFormatters(axisFormatters: self.axisFormatters)
                tab.chartEntries = self.chartViewModel.entries
                tab.setYAxisLimitLine(
                    value: self.chartViewModel.maxValue,
                    label: self.chartViewModel.formattedMaxValue
                )
                
                tab.identifier = self.identifier
            }
        }
        
        struct ChartUpdatedViewModel {
            
            let selectedPeriodIndex: Int
            
            let growth: String
            let growthPositive: Bool?
            let growthSinceDate: String
            
            let axisFormatters: Model.AxisFormatters
            let chartViewModel: Model.ChartViewModel
            
            // MARK: -
            
            func setup(tab: View) {
                tab.selectedDatePickerItemIndex = self.selectedPeriodIndex
                
                tab.growth = self.growth
                tab.growthPositive = self.growthPositive
                tab.growthSinceDate = self.growthSinceDate
                
                tab.setAxisFormatters(axisFormatters: self.axisFormatters)
                tab.chartEntries = self.chartViewModel.entries
                tab.setYAxisLimitLine(
                    value: self.chartViewModel.maxValue,
                    label: self.chartViewModel.formattedMaxValue
                )
            }
        }
        
        struct ChartEntrySelectedViewModel {
            
            let title: String
            let subTitle: String
            let identifier: TabIdentifier
            
            // MARK: -
            
            func setup(tab: View) {
                tab.title = self.title
                tab.subTitle = self.subTitle
                tab.identifier = self.identifier
            }
        }
        
        class View: UIView {
            
            typealias DidSelectPickerItem = (_ item: Int) -> Void
            typealias DidSelectChartItem = (_ itemIndex: Int?) -> Void
            
            // MARK: - Public properties
            
            public var didSelectPickerItem: DidSelectPickerItem?
            public var didSelectChartItem: DidSelectChartItem?
            
            public var identifier: TabIdentifier?
            
            public var title: String? {
                get { return self.titleLabel.text }
                set { self.titleLabel.text = newValue}
            }
            
            public var subTitle: String? {
                get { return self.subTitleLabel.text }
                set { self.subTitleLabel.text = newValue}
            }
            
            public var datePickerItems: [HorizontalPicker.Item] = [] {
                didSet {
                    self.datePicker.items = self.datePickerItems
                }
            }
            
            public var selectedDatePickerItemIndex: Int {
                get { return self.datePicker.selectedItemIndex }
                set { self.datePicker.setSelectedItemAtIndex(newValue, animated: false) }
            }
            
            public var growth: String? {
                get { return self.growthLabel.text }
                set { self.growthLabel.text = newValue}
            }
            
            public var growthPositive: Bool? = nil {
                didSet {
                    self.updateGrowthLabel()
                }
            }
            
            public var growthSinceDate: String? {
                get { return self.growthSinceDateLabel.text }
                set { self.growthSinceDateLabel.text = newValue}
            }
            
            public var chartEntries: [Model.ChartDataEntry]? {
                didSet {
                    self.chartView.entries = self.chartEntries?.map({ (chartEntry) -> ChartDataEntry in
                        return ChartDataEntry(x: chartEntry.x, y: chartEntry.y)
                    })
                }
            }
            
            private var currentLimitLine: ChartLimitLine? {
                willSet {
                    if let currLimit = self.currentLimitLine {
                        self.chartView.removeYAxisLimitLine(currLimit)
                    }
                }
                didSet {
                    if let currLimit = self.currentLimitLine {
                        self.chartView.addYAxisLimitLine(currLimit)
                    }
                }
            }
            
            private let chartCardValueFormatter: ChartCardValueFormatter = ChartCardValueFormatter()
            
            public var xAxisValueFormatter: IAxisValueFormatter? {
                get { return self.chartView.xAxisValueFormatter }
                set { self.chartView.xAxisValueFormatter = newValue }
            }
            
            public var yAxisValueFormatter: IAxisValueFormatter? {
                get { return self.chartView.yAxisValueFormatter }
                set { self.chartView.yAxisValueFormatter = newValue }
            }
            
            // MARK: - Private properties
            
            private let containerView: UIView = UIView()
            
            private let titleLabel: UILabel = UILabel()
            private let subTitleLabel: UILabel = UILabel()
            private let datePicker: HorizontalPicker = HorizontalPicker()
            private let growthLabel: UILabel = UILabel()
            private let growthSinceDateLabel: UILabel = UILabel()
            private let chartView: ChartView = ChartView()
            
            private let sideInset: CGFloat = 20
            private let topInset: CGFloat = 10
            private let bottomInset: CGFloat = 10
            
            // MARK: - Initializers
            
            override init(frame: CGRect) {
                super.init(frame: frame)
                
                self.commonInit()
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            // MARK: - Public
            
            func setAxisFormatters(axisFormatters: Model.AxisFormatters) {
                self.chartCardValueFormatter.string = { (value, axis) in
                    if axis is XAxis {
                        return axisFormatters.xAxisFormatter(value)
                    } else if axis is YAxis {
                        return axisFormatters.yAxisFormatter(value)
                    }
                    return ""
                }
            }
            
            func setYAxisLimitLine(value: Double, label: String) {
                let limitLine = ChartLimitLine(limit: value, label: label)
                limitLine.lineDashLengths = [5.0, 5.0]
                limitLine.lineColor = Theme.Colors.separatorOnContentBackgroundColor
                limitLine.valueTextColor = Theme.Colors.textOnContentBackgroundColor
                limitLine.valueFont = Theme.Fonts.smallTextFont
                limitLine.lineWidth = 1.0
                self.currentLimitLine = limitLine
            }
            
            // MARK: - Private
            
            private func commonInit() {
                self.setupView()
                self.setupContainerView()
                self.setupTitleLabel()
                self.setupSubTitleLabel()
                self.setupDatePicker()
                self.setupGrowthLabel()
                self.setupGrowthSinceDateLabel()
                self.setupChartView()
                
                self.setupLayout()
            }
            
            private func setupView() {
                self.backgroundColor = Theme.Colors.contentBackgroundColor
            }
            
            private func setupContainerView() {
                self.containerView.backgroundColor = Theme.Colors.contentBackgroundColor
            }
            
            private func setupSeparatorView(separator: UIView) {
                separator.backgroundColor = Theme.Colors.separatorOnContentBackgroundColor
            }
            
            private func setupTitleLabel() {
                self.titleLabel.font = Theme.Fonts.flexibleHeaderTitleFont
                self.titleLabel.textColor = Theme.Colors.textOnContentBackgroundColor
                self.titleLabel.textAlignment = .center
                self.titleLabel.numberOfLines = 1
            }
            
            private func setupSubTitleLabel() {
                self.setupSubTitleLabel(self.subTitleLabel)
            }
            
            private func setupSubTitleLabel(_ label: UILabel) {
                label.font = Theme.Fonts.smallTextFont
                label.textColor = Theme.Colors.textOnContentBackgroundColor
                label.textAlignment = .center
                label.numberOfLines = 1
            }
            
            private func setupDatePicker() {
                self.datePicker.backgroundColor = Theme.Colors.textOnMainColor
                self.datePicker.tintColor = Theme.Colors.mainColor
            }
            
            private func setupGrowthLabel() {
                self.growthLabel.font = Theme.Fonts.plainTextFont
                self.growthLabel.textColor = Theme.Colors.textOnContentBackgroundColor
                self.growthLabel.textAlignment = .center
                self.growthLabel.numberOfLines = 1
                
                self.updateGrowthLabel()
            }
            
            private func setupGrowthSinceDateLabel() {
                self.setupSubTitleLabel(self.growthSinceDateLabel)
            }
            
            private func setupChartView() {
                self.chartView.xAxisValueFormatter = self.chartCardValueFormatter
                self.chartView.yAxisValueFormatter = self.chartCardValueFormatter
                
                self.chartView.onDidSelectEntry = { [weak self] (_, index, _) in
                    self?.didSelectChartItem?(index)
                }
            }
            
            private func setupLayout() {
                self.addSubview(self.containerView)
                self.containerView.addSubview(self.titleLabel)
                self.containerView.addSubview(self.subTitleLabel)
                self.containerView.addSubview(self.datePicker)
                self.containerView.addSubview(self.growthLabel)
                self.containerView.addSubview(self.growthSinceDateLabel)
                self.containerView.addSubview(self.chartView)
                
                self.containerView.snp.makeConstraints { (make) in
                    make.leading.trailing.top.equalToSuperview()
                    make.height.lessThanOrEqualTo(self.snp.height)
                    make.bottom.lessThanOrEqualToSuperview()
                }
                
                self.titleLabel.snp.makeConstraints { (make) in
                    make.top.equalToSuperview().inset(self.topInset)
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                }
                
                self.subTitleLabel.snp.makeConstraints { (make) in
                    make.top.equalTo(self.titleLabel.snp.bottom).offset(self.topInset)
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                }
                
                self.datePicker.snp.makeConstraints { (make) in
                    make.top.equalTo(self.subTitleLabel.snp.bottom).offset(self.topInset)
                    make.leading.trailing.equalToSuperview()
                }
                
                self.growthLabel.snp.makeConstraints { (make) in
                    make.top.equalTo(self.datePicker.snp.bottom).offset(self.topInset)
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                }
                
                self.growthSinceDateLabel.snp.makeConstraints { (make) in
                    make.top.equalTo(self.growthLabel.snp.bottom).offset(self.topInset)
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                }
                
                self.chartView.snp.makeConstraints { (make) in
                    make.top.equalTo(self.growthSinceDateLabel.snp.bottom).offset(self.topInset)
                    make.leading.trailing.equalToSuperview()
                    make.bottom.equalToSuperview().inset(self.bottomInset)
                }
            }
            
            private func updateGrowthLabel() {
                if let growthPositive = self.growthPositive {
                    if growthPositive {
                        self.growthLabel.textColor = Theme.Colors.positiveAmountColor
                    } else {
                        self.growthLabel.textColor = Theme.Colors.negativeAmountColor
                    }
                } else {
                    self.growthLabel.textColor = Theme.Colors.neutralAmountColor
                }
            }
        }
    }
}
