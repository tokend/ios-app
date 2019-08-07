import Foundation
import TokenDSDK

protocol TokenDetailsDocumentURLBuilderProtocol {
    func getURLForTerms(_ terms: Asset.Details.Term) -> URL?
}

extension TokenDetailsScene {
    typealias DocumentURLBuilderProtocol = TokenDetailsDocumentURLBuilderProtocol
}
