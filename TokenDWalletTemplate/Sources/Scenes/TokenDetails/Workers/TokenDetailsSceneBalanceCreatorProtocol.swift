import Foundation

protocol TokenDetailsSceneBalanceCreatorProtocol {
    typealias CreateBalanceResult = BalanceCreatorProtocolCreateBalanceResult
    
    func createBalanceForAsset(
        _ asset: String,
        completion: @escaping (CreateBalanceResult) -> Void
    )
}

extension TokenDetailsScene {
    typealias BalanceCreatorProtocol = TokenDetailsSceneBalanceCreatorProtocol
}

extension BalanceCreator: TokenDetailsScene.BalanceCreatorProtocol { }
