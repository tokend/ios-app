import UIKit

protocol TokenDetailsTokenColoringProviderProtocol {
    func coloringForCode(_ code: String) -> UIColor
}

extension TokenDetailsScene {
    typealias TokenColoringProvider = TokenDetailsTokenColoringProviderProtocol
}
