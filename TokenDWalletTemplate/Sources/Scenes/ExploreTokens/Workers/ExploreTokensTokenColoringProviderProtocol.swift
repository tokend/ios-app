import UIKit

protocol ExploreTokensTokenColoringProviderProtocol {
    func coloringForCode(_ code: String) -> UIColor
}

extension ExploreTokensScene {
    typealias TokenColoringProvider = ExploreTokensTokenColoringProviderProtocol
}
