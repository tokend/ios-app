import Foundation
import Charts

extension BalancesList {
    
    public enum PieChartCell {
        
        public struct ViewModel: CellViewModel {
            var viewModel: Model.PieChartViewModel
            let cellIdentifier: Model.CellIdentifier
            
            public func setup(cell: View) {
                cell.viewModel = self.viewModel
                cell.cellIdentifier = self.cellIdentifier
            }
        }
        
        public class View: UITableViewCell {
            
            // MARK: - Public properties
            
            public var onChartBalanceSelected: ((Double) -> Void)?
            public var viewModel: Model.PieChartViewModel? {
                didSet {
                    guard let viewModel = self.viewModel else {
                        return
                    }
                    self.updatePieEntryData(viewModel: viewModel)
                }
            }
            
            var cellIdentifier: Model.CellIdentifier?
            
            // MARK: - Private properties
            
            private let pieChart: PieChartView = PieChartView()
            private var currentHighlight: Highlight?
            
            // MARK: -
            
            override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
                super.init(style: style, reuseIdentifier: reuseIdentifier)
                
                self.setupView()
                self.setupPieChartView()
                self.setupLayout()
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
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
            
            private func setupLayout() {
                self.addSubview(self.pieChart)
                
                self.pieChart.snp.makeConstraints { (make) in
                    make.leading.top.bottom.equalToSuperview().inset(20.0)
                    make.width.height.equalTo(175.0)
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
