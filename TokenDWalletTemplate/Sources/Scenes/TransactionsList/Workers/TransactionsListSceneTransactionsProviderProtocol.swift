import Foundation
import TokenDSDK
import RxSwift

protocol TransactionsListSceneTransactionsProviderProtocol {
    func observeParicipantEffects() -> Observable<[ParticipantEffectResource]>
    func observeLoadingStatus() -> Observable<TransactionsListScene.TransactionsFetcherProtocol.LoadingStatus>
    func observeLoadingMoreStatus() -> Observable<TransactionsListScene.TransactionsFetcherProtocol.LoadingStatus>
    func observeErrors() -> Observable<Swift.Error>
    
    func setBalanceId(_ balanceId: String)
    
    func loadMoreParicipantEffects()
    func reloadParicipantEffects()
}

extension TransactionsListScene {
    typealias TransactionsProviderProtocol = TransactionsListSceneTransactionsProviderProtocol
    typealias LoadingStatus = TransactionsListSceneTransactionsLoadingStatus
}
