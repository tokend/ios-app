import UIKit

protocol BalancesListPieChartColorsProviderProtocol {
    func getDefaultPieChartColors() -> [UIColor]
    func getPieChartColorForOther() -> UIColor
}

extension BalancesList {
    typealias PieChartColorsProviderProtocol = BalancesListPieChartColorsProviderProtocol
    
    class PieChartColorsProvider: PieChartColorsProviderProtocol {
        
        // MARK: - PieChartColorsProviderProtocol
        
        func getDefaultPieChartColors() -> [UIColor] {
            let colors: [UIColor] = [
                UIColor(red: 0.22, green: 0.64, blue: 0.58, alpha: 1),
                UIColor(red: 0.49, green: 0.45, blue: 0.98, alpha: 1),
                UIColor(red: 0.94, green: 0.63, blue: 0.15, alpha: 1),
                UIColor(red: 0.93, green: 0.33, blue: 0.33, alpha: 1)
            ]
            return colors
        }
        
        func getPieChartColorForOther() -> UIColor {
            return UIColor(red: 0.84, green: 0.84, blue: 0.84, alpha: 1)
        }
    }
}
