import Foundation
import UIKit
import RxSwift

extension SaleDetails {
    
    public enum GeneralContent {
        
        public typealias SectionViewModel = TransactionDetails.Model.SectionViewModel
        public typealias TitleValueCellModel = TitleValueTableViewCell.Model
        
        public struct Model {
            
            public let baseAsset: String
            public let defaultQuoteAsset: String
            public let hardCap: Decimal
            public let baseHardCap: Decimal
            public let softCap: Decimal
            public let startTime: Date
            public let endTime: Date
        }
        
        public struct ViewModel {
            
            public let sections: [SectionViewModel]
            
            public func setup(_ view: View) {
                view.sections = self.sections
            }
        }
        
        public class View: UIView {
            
            // MARK: - Public properties
            
            public var sections: [SectionViewModel] = [] {
                didSet {
                    self.saleDetailsTableView.reloadData()
                }
            }
            
            // MARK: - Private properties
            
            private let saleDetailsTableView: UITableView = UITableView(frame: .zero, style: .grouped)
            
            // MARK: - Override
            
            override init(frame: CGRect) {
                super.init(frame: frame)
                self.customInit()
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            // MARK: - Private
            
            private func customInit() {
                self.setupView()
                self.setupSaleDetailsTableView()
                self.setupLayout()
            }
            
            // MARK: - Setup
            
            private func setupView() {
                self.backgroundColor = Theme.Colors.contentBackgroundColor
            }
            
            private func setupSaleDetailsTableView() {
                let cellClasses: [CellViewAnyModel.Type] = [
                    TitleValueCellModel.self
                ]
                self.saleDetailsTableView.register(classes: cellClasses)
                self.saleDetailsTableView.dataSource = self
                self.saleDetailsTableView.rowHeight = UITableView.automaticDimension
                self.saleDetailsTableView.estimatedRowHeight = 125
                self.saleDetailsTableView.tableFooterView = UIView(frame: CGRect.zero)
                self.saleDetailsTableView.backgroundColor = Theme.Colors.containerBackgroundColor
                self.saleDetailsTableView.isUserInteractionEnabled = false
            }
            
            private func setupLayout() {
                self.addSubview(self.saleDetailsTableView)
                self.saleDetailsTableView.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
            }
        }
    }
}

extension SaleDetails.GeneralContent.View: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sections[section].cells.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = self.sections[indexPath.section].cells[indexPath.row]
        let cell = tableView.dequeueReusableCell(with: model, for: indexPath)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections[section].title
    }
    
    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return self.sections[section].description
    }
}
