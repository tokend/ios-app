import Foundation

protocol ExploreTokensSceneBalanceCreatorProtocol {
    typealias Asset = String
    typealias CreateBalanceResult = BalanceCreatorProtocolCreateBalanceResult
    
    func createBalanceForAsset(
        _ asset: Asset,
        completion: @escaping (CreateBalanceResult) -> Void
    )
}

extension ExploreTokensScene {
    typealias BalanceCreatorProtocol = ExploreTokensSceneBalanceCreatorProtocol
}

extension BalanceCreator: ExploreTokensScene.BalanceCreatorProtocol { }
