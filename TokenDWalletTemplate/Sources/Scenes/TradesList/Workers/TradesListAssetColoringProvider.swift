import UIKit

public protocol TradesListAssetColoringProviderProtocol {
    func coloringForCode(_ code: String) -> UIColor
}

extension TradesList {
    
    public typealias AssetColoringProvider = TradesListAssetColoringProviderProtocol
}

extension TokenColoringProvider: TradesList.AssetColoringProvider {}
