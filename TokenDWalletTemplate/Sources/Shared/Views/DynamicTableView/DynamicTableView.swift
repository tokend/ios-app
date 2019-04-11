import UIKit

public class DynamicTableView: UIView {
    
    // MARK: - Public properties
    
    public weak var dataSource: DynamicTableViewDataSourceDelegate? {
        didSet {
            self.reloadData()
        }
    }
    
    // MARK: - Private properties
    
    private let tableView: UITableView = UITableView()
    
    // MARK: -
    
    public init() {
        super.init(frame: CGRect.zero)
        
        self.setupTableView()
        self.setupLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public
    
    public func reloadData() {
        let showsCellSeparator = self.dataSource?.showsCellSeparator() ?? true
        if !showsCellSeparator {
            self.tableView.separatorStyle = .none
        }
        
        self.tableView.reloadData()
    }
    
    // MARK: - Private
    
    private func setupTableView() {
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 75.0
        
        self.tableView.register(
            DynamicContentTableViewCell.self,
            forCellReuseIdentifier: DynamicContentTableViewCell.identifier
        )
    }
    
    private func setupLayout() {
        self.addSubview(self.tableView)
        
        self.tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}

extension DynamicTableView: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.dataSource?.numberOfSections() ?? 0
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource?.numberOfRowsIn(section: section) ?? 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = DynamicContentTableViewCell.identifier
        guard let dataSource = self.dataSource,
            let cell = tableView.dequeueReusableCell(
                withIdentifier: identifier,
                for: indexPath
                ) as? DynamicContentTableViewCell else {
                    return UITableViewCell()
        }
        
        let currentContent = cell.content
        
        let newContent = dataSource.contentAt(
            indexPath: indexPath,
            currentContent: currentContent
        )
        
        if newContent != currentContent {
            cell.content = newContent
        }
        
        return cell
    }
}

extension DynamicTableView: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        self.dataSource?.onSelectRowAt(indexPath: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}
