import UIKit

extension TokenDetailsScene {
    
    enum CardView {
        
        struct CardViewModel: CellViewModel {
            let title: String
            let cells: [CellViewAnyModel]
            
            func setup(cell: View) {
                cell.title = self.title
                cell.cells = self.cells
            }
        }
        
        class View: UITableViewCell {
            
            // MARK: - Public properties
            
            public var didSelectCell: ((CellViewAnyModel) -> Void)?
            
            public var title: String? {
                get { return self.titleLabel.text }
                set { self.titleLabel.text = newValue }
            }
            
            public var cells: [CellViewAnyModel] = [] {
                didSet {
                    self.tableView.reloadData()
                    self.tableView.snp.remakeConstraints { (make) in
                        make.leading.trailing.equalToSuperview()
                        make.top.equalTo(self.titleLabel.snp.bottom).offset(self.topInset)
                        make.bottom.equalToSuperview().inset(self.topInset)
                        make.height.equalTo(self.tableViewHeight)
                    }
                }
            }
            
            // MARK: - Private properties
            
            private let container: UIView = UIView()
            private let titleLabel: UILabel = UILabel()
            private let tableView: UITableView = UITableView(frame: .zero, style: .grouped)
            
            private let sideInset: CGFloat = 15.0
            private let topInset: CGFloat = 10.0
            
            private var tableViewHeight: CGFloat {
                return self.tableView.contentSize.height
            }
            
            // MARK: -
            
            override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
                super.init(style: style, reuseIdentifier: reuseIdentifier)
                
                self.setupView()
                self.setupContainerView()
                self.setupTitleLabel()
                self.setupTableView()
                self.setupLayout()
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            // MARK: - Private
            
            private func setupView() {
                self.backgroundColor = Theme.Colors.clear
                self.selectionStyle = .none
            }
            
            private func setupContainerView() {
                self.container.backgroundColor = Theme.Colors.contentBackgroundColor
                self.container.layer.cornerRadius = 10.0
            }
            
            private func setupTitleLabel() {
                self.titleLabel.backgroundColor = Theme.Colors.contentBackgroundColor
                self.titleLabel.font = Theme.Fonts.largeTitleFont
            }

            private func setupTableView() {
                self.tableView.backgroundColor = Theme.Colors.contentBackgroundColor
                self.tableView.register(classes: [
                    TokenDetailsTokenDocumentCell.Model.self,
                    TokenDetailsTokenSummaryCell.Model.self
                    ]
                )
                self.tableView.dataSource = self
                self.tableView.delegate = self
                self.tableView.tableFooterView = UIView(frame: .zero)
                self.tableView.contentInset = .zero
                self.tableView.separatorStyle = .none
                self.tableView.isScrollEnabled = false
                self.tableView.estimatedRowHeight = 15.0
            }
            
            private func setupLayout() {
                self.contentView.addSubview(self.container)
                
                self.container.addSubview(self.titleLabel)
                self.container.addSubview(self.tableView)
                
                self.container.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.bottom.equalToSuperview()
                }
                
                self.titleLabel.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.equalToSuperview().inset(self.topInset)
                }
                
                self.tableView.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview()
                    make.top.equalTo(self.titleLabel.snp.bottom).offset(self.topInset)
                    make.bottom.lessThanOrEqualToSuperview().inset(self.topInset)
                }
            }
        }
    }
}

extension TokenDetailsScene.CardView.View: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.cells.isEmpty ? 0 : 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = self.cells[indexPath.row]
        let cell = tableView.dequeueReusableCell(with: model, for: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = cells[indexPath.row]
        self.didSelectCell?(model)
    }
}

extension TokenDetailsScene.CardView.View: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView(frame: .zero)
        header.frame.size.height = 0.0
        return header
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView(frame: .zero)
        footer.frame.size.height = 0.0
        return footer
    }
}
