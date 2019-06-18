import UIKit
import Charts

public protocol ChartDisplayLogic: class {
    typealias Event = Chart.Event
    
    func displayChartDidUpdate(viewModel: Event.ChartDidUpdate.ViewModel)
    func displaySelectChartPeriod(viewModel: Event.SelectChartPeriod.ViewModel)
    func displaySelectChartEntry(viewModel: Event.SelectChartEntry.ViewModel)
}

extension Chart {
    public typealias DisplayLogic = ChartDisplayLogic
    
    @objc(ChartViewController)
    public class ViewController: UIViewController {
        
        public typealias Event = Chart.Event
        public typealias Model = Chart.Model
        
        // MARK: - Private properties
        
        private let scrollView: UIScrollView = UIScrollView()
        private let containerView: UIView = UIView()
        
        private let titleLabel: UILabel = UILabel()
        private let subTitleLabel: UILabel = UILabel()
        private let datePicker: HorizontalPicker = HorizontalPicker()
        private let growthLabel: UILabel = UILabel()
        private let growthSinceDateLabel: UILabel = UILabel()
        private let chartView: ChartView = ChartView()
        private let emptyView: EmptyContent.View = EmptyContent.View()
        
        private let sideInset: CGFloat = 20
        private let topInset: CGFloat = 10
        private let bottomInset: CGFloat = 10
        
        private let chartCardValueFormatter: ChartValueFormatter = ChartValueFormatter()
        
        private var hardCapLimitLine: ChartLimitLine? {
            willSet {
                if let hardCapLimit = self.hardCapLimitLine {
                    self.chartView.removeYAxisLimitLine(hardCapLimit)
                }
            }
            didSet {
                if let hardCapLimit = self.hardCapLimitLine {
                    self.chartView.addYAxisLimitLine(hardCapLimit)
                }
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
        
        private var softCapLimitLine: ChartLimitLine? {
            willSet {
                if let softCapLimit = self.softCapLimitLine {
                    self.chartView.removeYAxisLimitLine(softCapLimit)
                }
            }
            didSet {
                if let softCapLimit = self.softCapLimitLine {
                    self.chartView.addYAxisLimitLine(softCapLimit)
                }
            }
        }
        
        // MARK: -
        
        deinit {
            self.onDeinit?(self)
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
        }
        
        // MARK: - Overridden
        
        public override func viewDidLoad() {
            super.viewDidLoad()
            
            self.commonInit()
            let request = Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
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
            self.setupEmptyView()
            
            self.setupLayout()
        }
        
        private func setAxisFormatters(axisFormatters: Model.AxisFormatters) {
            self.chartCardValueFormatter.string = { (value, axis) in
                if axis is XAxis {
                    return axisFormatters.xAxisFormatter(value)
                } else if axis is YAxis {
                    return axisFormatters.yAxisFormatter(value)
                }
                return ""
            }
        }
        
        private func addYAxisLimitLine(
            value: Double,
            label: String,
            type: Model.LimitLineType
            ) {
            
            let limitLine = ChartLimitLine(limit: value, label: label)
            limitLine.lineDashLengths = [5.0, 5.0]
            limitLine.lineColor = Theme.Colors.separatorOnContentBackgroundColor
            limitLine.valueTextColor = Theme.Colors.textOnContentBackgroundColor
            limitLine.valueFont = Theme.Fonts.smallTextFont
            limitLine.lineWidth = 1.0
            limitLine.labelPosition = .leftBottom
            
            switch type {
                
            case .current:
                self.currentLimitLine = limitLine
                
            case .hardCap:
                self.hardCapLimitLine = limitLine
                
            case .softCap:
                self.softCapLimitLine = limitLine
            }
        }
        
        // MARK: - Setup
        
        private func updateChartContent(viewModel: Model.ChartViewModel) {
            self.titleLabel.text = viewModel.title
            self.subTitleLabel.text = viewModel.subTitle
            
            self.datePicker.items = viewModel.datePickerItems.map({ (period) -> HorizontalPicker.Item in
                return HorizontalPicker.Item(
                    title: period.title,
                    enabled: period.isEnabled,
                    onSelect: { [weak self] in
                        let request = Event.SelectChartPeriod.Request(period: period.period.rawValue)
                        self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                            businessLogic.onSelectChartPeriod(request: request)
                        })
                })
            })
            self.datePicker.setSelectedItemAtIndex(
                viewModel.selectedDatePickerItemIndex,
                animated: false
            )
            
            self.growthLabel.text = viewModel.growth
            self.updateGrowthLabel(growthPositive: viewModel.growthPositive)
            self.growthSinceDateLabel.text = viewModel.growthSinceDate
            
            self.setAxisFormatters(axisFormatters: viewModel.axisFormatters)
            let entries = viewModel.chartInfoViewModel.entries
            self.chartView.entries = entries.map({ (chartEntry) -> ChartDataEntry in
                return ChartDataEntry(x: chartEntry.x, y: chartEntry.y)
            })
            viewModel.chartInfoViewModel.limits.forEach { (limit) in
                self.addYAxisLimitLine(
                    value: limit.value,
                    label: limit.label,
                    type: limit.type
                )
            }
        }
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupScrollView() {
            self.scrollView.backgroundColor = Theme.Colors.clear
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
            self.datePicker.backgroundColor = Theme.Colors.textOnAccentColor
            self.datePicker.tintColor = Theme.Colors.darkAccentColor
        }
        
        private func setupGrowthLabel() {
            self.growthLabel.font = Theme.Fonts.plainTextFont
            self.growthLabel.textColor = Theme.Colors.textOnContentBackgroundColor
            self.growthLabel.textAlignment = .center
            self.growthLabel.numberOfLines = 1
            
            self.updateGrowthLabel(growthPositive: nil)
        }
        
        private func setupGrowthSinceDateLabel() {
            self.setupSubTitleLabel(self.growthSinceDateLabel)
        }
        
        private func setupChartView() {
            self.chartView.xAxisValueFormatter = self.chartCardValueFormatter
            self.chartView.yAxisValueFormatter = self.chartCardValueFormatter
            
            self.chartView.onDidSelectEntry = { [weak self] (_, index, _) in
                let request = Event.SelectChartEntry.Request(chartEntryIndex: index)
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onSelectChartEntry(request: request)
                })
            }
        }
        
        private func setupEmptyView() {
            self.emptyView.isHidden = true
        }
        
        private func setupLayout() {
            self.view.addSubview(self.scrollView)
            self.scrollView.addSubview(self.containerView)
            self.containerView.addSubview(self.titleLabel)
            self.containerView.addSubview(self.subTitleLabel)
            self.containerView.addSubview(self.datePicker)
            self.containerView.addSubview(self.growthLabel)
            self.containerView.addSubview(self.growthSinceDateLabel)
            self.containerView.addSubview(self.chartView)
            self.containerView.addSubview(self.emptyView)
            
            self.scrollView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            
            self.containerView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
                make.size.equalTo(self.view.snp.size)
            }
            
            self.emptyView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
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
        
        private func updateGrowthLabel(growthPositive: Bool?) {
            if let growthPositive = growthPositive {
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

extension Chart.ViewController: Chart.DisplayLogic {
    
    public func displayChartDidUpdate(viewModel: Event.ChartDidUpdate.ViewModel) {
        switch viewModel {
            
        case .chart(let viewModel):
            self.emptyView.isHidden = true
            self.updateChartContent(viewModel: viewModel)
            
        case .error(let model):
            self.emptyView.isHidden = false
            model.setup(self.emptyView)
        }
    }
    
    public func displaySelectChartPeriod(viewModel: Event.SelectChartPeriod.ViewModel) {
        self.datePicker.setSelectedItemAtIndex(
            viewModel.viewModel.selectedPeriodIndex,
            animated: false
        )
        
        self.growthLabel.text = viewModel.viewModel.growth
        self.updateGrowthLabel(growthPositive: viewModel.viewModel.growthPositive)
        self.growthSinceDateLabel.text = viewModel.viewModel.growthSinceDate
        
        self.setAxisFormatters(axisFormatters: viewModel.viewModel.axisFormatters)
        let entries = viewModel.viewModel.chartInfoViewModel.entries
        self.chartView.entries = entries.map({ (chartEntry) -> ChartDataEntry in
            return ChartDataEntry(x: chartEntry.x, y: chartEntry.y)
        })
        
        viewModel.viewModel.chartInfoViewModel.limits.forEach { (limit) in
            self.addYAxisLimitLine(
                value: limit.value,
                label: limit.label,
                type: limit.type
            )
        }
    }
    
    public func displaySelectChartEntry(viewModel: Event.SelectChartEntry.ViewModel) {
        self.titleLabel.text = viewModel.viewModel.title
        self.subTitleLabel.text = viewModel.viewModel.subTitle
    }
}
