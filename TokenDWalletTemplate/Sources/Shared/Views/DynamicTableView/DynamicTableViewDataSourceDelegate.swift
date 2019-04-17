import UIKit

public protocol DynamicTableViewDataSourceDelegate: class {
    
    // MARK: - Data source
    
    func numberOfSections() -> Int
    
    func numberOfRowsIn(section: Int) -> Int
    
    func contentAt(indexPath: IndexPath, currentContent: UIView?) -> UIView?
    
    // MARK: - Delegate
    
    func onSelectRowAt(indexPath: IndexPath)
    
    // MARK: - Configs
    
    func showsCellSeparator() -> Bool
}
