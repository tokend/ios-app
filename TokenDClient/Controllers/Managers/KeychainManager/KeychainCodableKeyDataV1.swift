import Foundation

class KeychainCodableKeyDataV1: Codable {

    // MARK: - Public properties

    var seeds: [String]

    // MARK: -

    init(seeds: [String]) {
        self.seeds = seeds
    }
}
