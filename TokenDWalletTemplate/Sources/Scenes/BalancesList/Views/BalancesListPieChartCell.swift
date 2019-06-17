import Foundation
import Charts

extension BalancesList {
    
    public enum PieChartCell {
        
        public struct ViewModel: CellViewModel {
            var chartViewModel: Model.PieChartViewModel
            var legendCells: [LegendCell.ViewModel]
            let cellIdentifier: Model.CellIdentifier
            
            public func setup(cell: View) {
                cell.chartViewModel = self.chartViewModel
                cell.legendCells = self.legendCells
                cell.cellIdentifier = self.cellIdentifier
            }
        }
        
        public class View: UITableViewCell {
            
            // MARK: - Public properties
            
            public var onChartBalanceSelected: ((Double) -> Void)?
            public var chartViewModel: Model.PieChartViewModel? {
                didSet {
                    guard let chartViewModel = self.chartViewModel else {
                        return
                    }
                    self.updatePieEntryData(viewModel: chartViewModel)
                }
            }
            
            public var legendCells: [LegendCell.ViewModel] = [] {
                didSet {
                    self.legendTableView.reloadData()
                }
            }
            
            var cellIdentifier: Model.CellIdentifier?
            
            // MARK: - Private properties
            
            private let pieChart: PieChartView = PieChartView()
            private let legendTableView: UITableView = UITableView(frame: .zero, style: .grouped)
            private var currentHighlight: Highlight?
            
            private let sideInset: CGFloat = 20.0
            private var chartHasBeenAnimated: Bool = false
            
            // MARK: -
            
            override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
                super.init(style: style, reuseIdentifier: reuseIdentifier)
                
                self.setupView()
                self.setupPieChartView()
                self.setupLegendTableView()
                self.setupLayout()
            }
            
            required init?(coder aDecoder: NSCoder) {
                super.init(coder: aDecoder)
                
                self.setupView()
                self.setupPieChartView()
                self.setupLegendTableView()
                self.setupLayout()
            }
            
            // MARK: - Public
            
            func updatePieEntryData(viewModel: Model.PieChartViewModel) {
                let entries = viewModel.entries.map { (entry) -> PieChartDataEntry in
                    return PieChartDataEntry(value: entry.value)
                }
                let set = PieChartDataSet(values: entries, label: nil)
                set.selectionShift = 4.0
                set.sliceSpace = 0
                set.drawValuesEnabled = false
                set.colors = viewModel.colorsPallete
                
                self.pieChart.data = PieChartData(dataSet: set)
                
                if let highlitedEntry = viewModel.highlitedEntry {
                    let highlight = Highlight(
                        x: highlitedEntry.index,
                        dataSetIndex: 0,
                        stackIndex: 0
                    )
                    self.currentHighlight = highlight
                    self.pieChart.highlightValue(self.currentHighlight)
                    self.pieChart.centerAttributedText = highlitedEntry.value
                    
                    if !self.chartHasBeenAnimated {
                        self.chartHasBeenAnimated = true
                        self.pieChart.animate(xAxisDuration: 0.5, yAxisDuration: 0.5)
                    }
                }
            }
            
            // MARK: - Private
            
            private func setupView() {
                self.backgroundColor = Theme.Colors.contentBackgroundColor
                self.selectionStyle = .none
            }
            
            private func setupPieChartView() {
                self.pieChart.chartDescription = nil
                self.pieChart.drawEntryLabelsEnabled = false
                self.pieChart.legend.enabled = false
                self.pieChart.delegate = self
            }
            
            private func setupLegendTableView() {
                self.legendTableView.backgroundColor = Theme.Colors.contentBackgroundColor
                self.legendTableView.delegate = self
                self.legendTableView.dataSource = self
                self.legendTableView.register(classes: [
                    LegendCell.ViewModel.self
                    ]
                )
                self.legendTableView.separatorStyle = .none
                self.legendTableView.estimatedRowHeight = 35.0
                self.legendTableView.isScrollEnabled = false
                self.legendTableView.contentInset = UIEdgeInsets(
                    top: 0.0,
                    left: self.sideInset / 2,
                    bottom: 0.0,
                    right: self.sideInset / 2
                )
            }
            
            private func setupLayout() {
                self.addSubview(self.pieChart)
                self.addSubview(self.legendTableView)
                
                self.pieChart.snp.makeConstraints { (make) in
                    make.leading.top.bottom.equalToSuperview().inset(self.sideInset)
                    make.width.equalTo(self.frame.width / 2)
                }
                
                self.legendTableView.snp.makeConstraints { (make) in
                    make.trailing.top.bottom.equalToSuperview().inset(self.sideInset)
                    make.leading.equalTo(self.pieChart.snp.trailing)
                    make.height.equalTo(200.0)
                }
            }
        }
    }
}

extension BalancesList.PieChartCell.View: ChartViewDelegate {
    
    public func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        guard let entry = entry as? PieChartDataEntry else {
            return
        }
        self.onChartBalanceSelected?(entry.value)
    }
    
    public func chartValueNothingSelected(_ chartView: ChartViewBase) {
        self.pieChart.highlightValue(self.currentHighlight)
    }
}

extension BalancesList.PieChartCell.View: UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.legendCells.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = self.legendCells[indexPath.row]
        let cell = self.legendTableView.dequeueReusableCell(with: model, for: indexPath)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
}

extension BalancesList.PieChartCell.View: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = self.legendCells[indexPath.row]
        self.onChartBalanceSelected?(model.percentageValue)
    }
}
