import Foundation
import RxCocoa
import RxSwift

protocol TokenDetailsBusinessLogic {
    func onViewDidLoad(request: TokenDetailsScene.Event.ViewDidLoad.Request)
    func onDidSelectAction(request: TokenDetailsScene.Event.DidSelectAction.Request)
}

extension TokenDetailsScene {
    typealias BusinessLogic = TokenDetailsBusinessLogic
    
    class Interactor {
        
        private let presenter: PresentationLogic
        private let tokenIdentifier: TokenIdentifier
        private let balanceCreator: BalanceCreatorProtocol
        private let tokenDetailsFetcher: TokenDetailsFetcherProtocol
        private let originalAccountId: String
        
        private var sceneModel: Model.SceneModel
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        init(
            presenter: PresentationLogic,
            tokenIdentifier: TokenIdentifier,
            balanceCreator: BalanceCreatorProtocol,
            tokenDetailsFetcher: TokenDetailsFetcherProtocol,
            originalAccountId: String
            ) {
            
            self.sceneModel = Model.SceneModel(token: nil)
            
            self.presenter = presenter
            self.tokenIdentifier = tokenIdentifier
            self.balanceCreator = balanceCreator
            self.tokenDetailsFetcher = tokenDetailsFetcher
            
            self.originalAccountId = originalAccountId
        }
        
        private func observeTokenDetails() {
            self.tokenDetailsFetcher
                .observeTokenWithIdentifier(self.tokenIdentifier)
                .subscribe(onNext: { [weak self] (token) in
                    self?.sceneModel.token = token
                    let response = TokenDetailsScene.Event.TokenDidUpdate.Response(token: token)
                    self?.presenter.presentTokenDidUpdate(response: response)
                })
                .disposed(by: self.disposeBag)
        }
    }
}

extension TokenDetailsScene.Interactor: TokenDetailsScene.BusinessLogic {
    func onViewDidLoad(request: TokenDetailsScene.Event.ViewDidLoad.Request) {
        self.observeTokenDetails()
    }
    
    func onDidSelectAction(request: TokenDetailsScene.Event.DidSelectAction.Request) {
        let identifier = self.tokenIdentifier
        guard let token = self.tokenDetailsFetcher.tokenForIdentifier(identifier)
            else {
                return
        }
        
        switch token.balanceState {
        case .created(let balanceId):
            self.presenter.presentDidSelectAction(response: .viewHistory(balanceId: balanceId))
        case .creating:
            break
        case .notCreated:
            self.balanceCreator.createBalanceForAsset(
                token.code,
                completion: { (_) in }
            )
        }
    }
}
