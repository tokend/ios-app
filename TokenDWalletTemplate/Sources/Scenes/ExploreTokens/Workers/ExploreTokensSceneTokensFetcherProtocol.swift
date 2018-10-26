import Foundation
import RxSwift
import RxCocoa

enum ExploreTokensSceneTokensFetcherLoadingStatus {
    case loading
    case loaded
}

protocol ExploreTokensSceneTokensFetcherProtocol {
    typealias Token = ExploreTokensScene.Model.Token
    typealias LoadingStatus = ExploreTokensSceneTokensFetcherLoadingStatus
    typealias TokenIdentifier = ExploreTokensScene.TokenIdentifier
    
    func reloadTokens()
    func observeTokens() -> Observable<[Token]>
    func observeLoadingStatus() -> Observable<LoadingStatus>
    func observeErrorStatus() -> Observable<Swift.Error>
    func tokenForIdentifier(_ identifier: TokenIdentifier) -> Token?
    func changeFilter(_ filter: String)
}

extension ExploreTokensScene {
    typealias TokensFetcherProtocol = ExploreTokensSceneTokensFetcherProtocol
}
