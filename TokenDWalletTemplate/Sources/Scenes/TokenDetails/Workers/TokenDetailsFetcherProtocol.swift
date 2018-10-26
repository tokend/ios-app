import Foundation
import RxCocoa
import RxSwift

protocol TokenDetailsFetcherProtocol {
    typealias Token = TokenDetailsScene.Model.Token
    typealias TokenIdentifier = TokenDetailsScene.TokenIdentifier
    
    func observeTokenWithIdentifier(_ identifier: TokenIdentifier) -> Observable<Token?>
    func tokenForIdentifier(_ identifier: TokenIdentifier) -> Token?
}

extension TokenDetailsScene {
    typealias TokenDetailsFetcherProtocol = TokenDWalletTemplate.TokenDetailsFetcherProtocol
}
