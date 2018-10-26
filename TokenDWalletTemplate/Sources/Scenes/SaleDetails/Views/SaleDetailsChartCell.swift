import UIKit
import Charts

extension SaleDetails {
    
    enum ChartCell {
        
        struct ViewModel: CellViewModel {
            
            let title: String
            let subTitle: String
            
            let datePickerItems: [Model.PeriodViewModel]
            let selectedDatePickerItemIndex: Int
            
            let growth: String
            let growthPositive: Bool?
            let growthSinceDate: String
            
            let axisFormatters: Model.AxisFormatters
            let chartViewModel: Model.ChartViewModel
            
            let identifier: CellIdentifier
            
            // MARK: -
            
            func setup(cell: View) {
                cell.title = self.title
                cell.subTitle = self.subTitle
                
                weak var weakCell = cell
                cell.datePickerItems = self.datePickerItems.map({ (period) -> HorizontalPicker.Item in
                    return HorizontalPicker.Item(
                        title: period.title,
                        enabled: period.isEnabled,
                        onSelect: {
                            weakCell?.didSelectPickerItem?(period.period.rawValue)
                    })
                })
                cell.selectedDatePickerItemIndex = self.selectedDatePickerItemIndex
                
                cell.growth = self.growth
                cell.growthPositive = self.growthPositive
                cell.growthSinceDate = self.growthSinceDate
                cell.setAxisFormatters(axisFormatters: self.axisFormatters)
                cell.chartEntries = self.chartViewModel.entries
                cell.setYAxisLimitLine(
                    value: self.chartViewModel.maxValue,
                    label: self.chartViewModel.formattedMaxValue
                )
                
                cell.identifier = self.identifier
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
            
            func setup(cell: View) {
                cell.selectedDatePickerItemIndex = self.selectedPeriodIndex
                
                cell.growth = self.growth
                cell.growthPositive = self.growthPositive
                cell.growthSinceDate = self.growthSinceDate
                
                cell.setAxisFormatters(axisFormatters: self.axisFormatters)
                cell.chartEntries = self.chartViewModel.entries
                cell.setYAxisLimitLine(
                    value: self.chartViewModel.maxValue,
                    label: self.chartViewModel.formattedMaxValue
                )
            }
        }
        
        struct ChartEntrySelectedViewModel {
            
            let title: String
            let subTitle: String
            let identifier: CellIdentifier
            
            // MARK: -
            
            func setup(cell: View) {
                cell.title = self.title
                cell.subTitle = self.subTitle
            }
        }
        
        class View: UITableViewCell {
            
            typealias DidSelectPickerItem = (_ item: Int) -> Void
            typealias DidSelectChartItem = (_ itemIndex: Int?) -> Void
            
            // MARK: - Public properties
            
            public var didSelectPickerItem: DidSelectPickerItem?
            public var didSelectChartItem: DidSelectChartItem?
            
            public var identifier: CellIdentifier?
            
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
            
            override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
                super.init(style: style, reuseIdentifier: reuseIdentifier)
                
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
                self.selectionStyle = .none
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
                self.contentView.addSubview(self.titleLabel)
                self.contentView.addSubview(self.subTitleLabel)
                self.contentView.addSubview(self.datePicker)
                self.contentView.addSubview(self.growthLabel)
                self.contentView.addSubview(self.growthSinceDateLabel)
                self.contentView.addSubview(self.chartView)
                
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
