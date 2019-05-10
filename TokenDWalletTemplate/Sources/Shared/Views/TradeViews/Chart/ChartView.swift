import UIKit
import Charts

class ChartView: UIView {
    
    typealias DidSelectEntry = (_ datasetIndex: Int?, _ index: Int?, _ chartView: ChartView) -> Void
    
    // MARK: - Public properties
    
    public var onDidSelectEntry: DidSelectEntry?
    public var xAxisValueFormatter: IAxisValueFormatter? {
        get { return self.chart.xAxis.valueFormatter }
        set { self.chart.xAxis.valueFormatter = newValue }
    }
    public var yAxisValueFormatter: IAxisValueFormatter? {
        get { return self.yAxis.valueFormatter }
        set { self.yAxis.valueFormatter = newValue }
    }
    public var entries: [ChartDataEntry] = [] {
        didSet {
            if self.entries.isEmpty {
                self.chart.clear()
            } else {
                self.setDataWithEntries(self.entries)
            }
            self.chart.notifyDataSetChanged()
        }
    }
    public var yAxisMaximum: Double? {
        get { return self.yAxis.axisMaximum }
        set {
            if let maximum = newValue {
                self.yAxis.axisMaximum = maximum
            } else {
                self.yAxis.resetCustomAxisMax()
            }
        }
    }
    public var yAxisMinimum: Double? {
        get { return self.yAxis.axisMinimum }
        set {
            if let minimum = newValue {
                self.yAxis.axisMinimum = minimum
            } else {
                self.yAxis.resetCustomAxisMin()
            }
        }
    }
    public var isHighlighted: Bool {
        return !self.chart.highlighted.isEmpty
    }
    public var noDataText: String {
        get { return self.chart.noDataText }
        set { self.chart.noDataText = newValue }
    }
    public var yAxis: YAxis {
        return self.chart.leftAxis
    }
    
    // MARK: - Private properties
    
    private let chart: LineChartView = LineChartView()
    
    // MARK: - Overridden methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public
    
    public func addYAxisLimitLine(_ line: ChartLimitLine) {
        self.yAxis.addLimitLine(line)
    }
    
    public func removeYAxisLimitLine(_ line: ChartLimitLine) {
        self.yAxis.removeLimitLine(line)
    }
    
    // MARK: - Private
    
    private func setDataWithEntries(_ entries: [ChartDataEntry]) {
        let dataSet = LineChartDataSet()
        
        entries.forEach { (entry) in
            _ = dataSet.addEntry(entry)
        }
        
        dataSet.drawCirclesEnabled = false
        dataSet.drawCircleHoleEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.mode = .horizontalBezier
        dataSet.colors = [Theme.Colors.separatorOnMainColor]
        dataSet.drawHorizontalHighlightIndicatorEnabled = false
        dataSet.highlightColor = Theme.Colors.separatorOnMainColor
        dataSet.highlightLineWidth = 2
        dataSet.lineWidth = 1.5
        dataSet.drawFilledEnabled = true
        
        let colors = [
            Theme.Colors.textOnMainColor.cgColor,
            Theme.Colors.separatorOnMainColor.cgColor
        ]
        
        if let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors as CFArray,
            locations: [0.0, 0.6]
            ) {
            
            let fill = Fill(linearGradient: gradient, angle: 90)
            dataSet.fill = fill
        }
        
        chart.data = LineChartData(dataSets: [dataSet])
    }
    
    private func commonInit() {
        self.setupChart()
        self.setupLayout()
    }
    
    private func setupChart() {
        self.chart.noDataFont =  Theme.Fonts.smallTextFont
        self.chart.noDataTextColor = Theme.Colors.sideTextOnContentBackgroundColor
        self.noDataText = ""
        self.chart.pinchZoomEnabled = true
        self.chart.chartDescription?.enabled = false
        self.chart.delegate = self
        self.chart.drawGridBackgroundEnabled = false
        self.chart.pinchZoomEnabled = false
        self.chart.dragEnabled = true
        self.chart.drawBordersEnabled = false
        self.chart.drawGridBackgroundEnabled = false
        self.chart.doubleTapToZoomEnabled = false
        self.chart.highlightPerTapEnabled = false
        self.chart.highlightPerDragEnabled = true
        self.chart.setScaleEnabled(false)
        self.chart.autoScaleMinMaxEnabled = true
        self.chart.keepPositionOnRotation = true
        self.chart.extraBottomOffset = 5
        self.chart.drawMarkers = false
        self.chart.minOffset = 0
        
        self.chart.xAxis.labelPosition = .bottom
        self.chart.xAxis.drawGridLinesEnabled = false
        self.chart.xAxis.drawAxisLineEnabled = true
        self.chart.xAxis.axisLineColor =  Theme.Colors.separatorOnMainColor
        self.chart.xAxis.axisLineWidth = 1
        self.chart.xAxis.labelFont =  Theme.Fonts.smallTextFont
        self.chart.xAxis.labelTextColor =  Theme.Colors.sideTextOnContentBackgroundColor
        self.chart.xAxis.avoidFirstLastClippingEnabled = true
        self.chart.xAxis.labelHeight = 30
        self.chart.xAxis.setLabelCount(5, force: true)
        
        self.chart.rightAxis.enabled = false
        self.chart.rightAxis.drawGridLinesEnabled = false
        
        self.chart.leftAxis.drawGridLinesEnabled = true
        self.chart.leftAxis.drawAxisLineEnabled = false
        self.chart.leftAxis.drawLabelsEnabled = true
        self.chart.leftAxis.drawTopYLabelEntryEnabled = false
        self.chart.leftAxis.drawBottomYLabelEntryEnabled = false
        self.chart.leftAxis.yOffset = -10
        self.chart.leftAxis.labelPosition = .insideChart
        self.chart.leftAxis.labelFont = Theme.Fonts.smallTextFont
        self.chart.leftAxis.labelTextColor = Theme.Colors.sideTextOnContentBackgroundColor
        self.chart.leftAxis.setLabelCount(1, force: true)
        
        self.chart.legend.enabled = false
    }
    
    private func setupLayout() {
        self.addSubview(self.chart)
        self.chart.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}

extension ChartView: ChartViewDelegate {
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        if let entryIndex = chartView.data?.getDataSetByIndex(highlight.dataSetIndex)?.entryIndex(entry: entry) {
            self.onDidSelectEntry?(highlight.dataSetIndex, entryIndex, self)
        } else {
            self.onDidSelectEntry?(nil, nil, self)
        }
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        self.onDidSelectEntry?(nil, nil, self)
    }
}
