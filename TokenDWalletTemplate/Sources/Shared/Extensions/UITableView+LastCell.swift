import UIKit

extension UITableView {
    
    public func isLastCellVisible(lastCellIndexPath: IndexPath? = nil) -> Bool {
        let numberOfSections = self.numberOfSections
        guard numberOfSections > 0 else {
            return true
        }
        
        var lastPossibleCellIndexPath: IndexPath?
        
        if let lastIndexPath = lastCellIndexPath {
            lastPossibleCellIndexPath = lastIndexPath
        } else {
            var currSectionIndex: Int = numberOfSections - 1
            while currSectionIndex >= 0, lastPossibleCellIndexPath == nil {
                let numberOfCells = self.numberOfRows(inSection: currSectionIndex)
                
                if numberOfCells > 0 {
                    lastPossibleCellIndexPath = IndexPath(row: numberOfCells - 1, section: currSectionIndex)
                } else {
                    currSectionIndex -= 1
                }
            }
        }
        
        guard let indexPath = lastPossibleCellIndexPath else {
            return true
        }
        
        let cell = self.cellForRow(at: indexPath)
        
        return cell != nil
    }
}
