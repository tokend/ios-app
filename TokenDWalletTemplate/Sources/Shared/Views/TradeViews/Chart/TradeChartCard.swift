import UIKit
import Charts

class TradeChartCard: UIView {
    
    typealias DidSelectItemAtIndex = (_ index: Int?, _ card: TradeChartCard) -> Void
    
    // MARK: - Public properties
    
    public var xAxisValueFormatter: IAxisValueFormatter? {
        get { return self.chartView.xAxisValueFormatter }
        set { self.chartView.xAxisValueFormatter = newValue }
    }
    public var yAxisValueFormatter: IAxisValueFormatter? {
        get { return self.chartView.yAxisValueFormatter }
        set { self.chartView.yAxisValueFormatter = newValue }
    }
    
    public var didSelectItemAtIndex: DidSelectItemAtIndex?
    
    public var chartEntries: [ChartDataEntry] {
        get { return self.chartView.entries }
        set {
            self.chartView.entries = newValue
            self.updateEmptyMessage()
        }
    }
    
    public var periods: [HorizontalPicker.Item] {
        set { self.periodPicker.items = newValue }
        get { return self.periodPicker.items }
    }
    
    public var title: String? {
        get { return self.mainTitleLabel.text }
        set { self.mainTitleLabel.text = newValue }
    }
    public var subtitle: String? {
        get { return self.sideTitleLabel.text }
        set { self.sideTitleLabel.text = newValue }
    }
    
    public var emptyMessage: String? {
        get { return self.emptyMessageLabel.text }
        set {
            self.emptyMessageLabel.text = newValue
            self.updateEmptyMessage()
        }
    }
    
    // MARK: - Private properties
    
    private let titleStackView: UIStackView = UIStackView()
    private let mainTitleLabel: UILabel = UILabel()
    private let sideTitleLabel: UILabel = UILabel()
    private let emptyMessageLabel: UILabel = UILabel()
    
    private let periodPicker: HorizontalPicker = HorizontalPicker()
    private let chartView: ChartView = ChartView()
    
    // MARK: -
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public
    
    public func showChartLoading(_ show: Bool) {
        if show {
            self.chartView.showLoading()
        } else {
            self.chartView.hideLoading()
        }
    }
    
    public func selectPeriodAtIndex(_ index: Int) {
        self.periodPicker.setSelectedItemAtIndex(index, animated: false)
    }
    
    // MARK: - Private
    
    private func commonInit() {
        self.setupPeriodPicker()
        self.setupCard()
        self.setupTitleStackView()
        self.setupMainTitleLabel()
        self.setupSideTitleLabel()
        self.setupEmptyMessageLabel()
        self.setupChart()
        self.setupLayout()
    }
    
    private func setupCard() {
        self.backgroundColor = Theme.Colors.contentBackgroundColor
    }
    
    private func setupPeriodPicker() {
        self.periodPicker.backgroundColor = Theme.Colors.textOnAccentColor
        self.periodPicker.tintColor = Theme.Colors.darkAccentColor
    }
    
    private func setupTitleStackView() {
        self.titleStackView.alignment = .fill
        self.titleStackView.axis = .vertical
        self.titleStackView.distribution = .fill
        self.titleStackView.spacing = 4
    }
    
    private func setupMainTitleLabel() {
        self.mainTitleLabel.textAlignment = .center
        self.mainTitleLabel.textColor =  Theme.Colors.textOnContentBackgroundColor
        self.mainTitleLabel.font = Theme.Fonts.flexibleHeaderTitleFont
        self.mainTitleLabel.numberOfLines = 1
        self.mainTitleLabel.text = Localized(.main_title)
    }
    
    private func setupSideTitleLabel() {
        self.sideTitleLabel.textAlignment = .center
        self.sideTitleLabel.textColor =  Theme.Colors.textOnContentBackgroundColor
        self.sideTitleLabel.font = Theme.Fonts.smallTextFont
        self.sideTitleLabel.numberOfLines = 1
        self.sideTitleLabel.text = Localized(.side_title)
    }
    
    private func setupEmptyMessageLabel() {
        self.emptyMessageLabel.textColor = Theme.Colors.sideTextOnContainerBackgroundColor
        self.emptyMessageLabel.font = Theme.Fonts.smallTextFont
        self.emptyMessageLabel.textAlignment = .center
        self.emptyMessageLabel.numberOfLines = 0
    }
    
    private func setupChart() {
        self.chartView.onDidSelectEntry = { [weak self] (dataSetIndex, entryIndex, chart) in
            guard let strongSelf = self else { return }
            strongSelf.didSelectItemAtIndex?(entryIndex, strongSelf)
        }
    }
    
    private func setupLayout() {
        self.addSubview(self.titleStackView)
        self.addSubview(self.periodPicker)
        self.addSubview(self.chartView)
        self.addSubview(self.emptyMessageLabel)
        
        self.titleStackView.addArrangedSubview(self.mainTitleLabel)
        self.titleStackView.addArrangedSubview(self.sideTitleLabel)
        
        self.titleStackView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        self.periodPicker.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        self.chartView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        self.titleStackView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview().inset(24)
            make.top.equalToSuperview().inset(32)
        }
        
        self.periodPicker.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.titleStackView.snp.bottom).offset(32)
        }
        
        self.chartView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.periodPicker.snp.bottom).offset(16.0)
            make.bottom.equalTo(self.safeArea.bottom)
        }
        
        self.emptyMessageLabel.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview().inset(15.0)
            make.centerY.equalToSuperview()
        }
    }
    
    private func updateEmptyMessage() {
        let chartsHidden = self.chartEntries.isEmpty
        
        self.titleStackView.isHidden = chartsHidden
        self.periodPicker.isHidden = chartsHidden
        self.chartView.isHidden = chartsHidden
        self.emptyMessageLabel.isHidden = !chartsHidden
    }
}
