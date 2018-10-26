import Foundation
import RxSwift
import RxCocoa

protocol ExploreTokensBusinessLogic {
    func onViewDidLoad(request: ExploreTokensScene.Event.ViewDidLoad.Request)
    func onDidInitiateRefresh(request: ExploreTokensScene.Event.DidInitiateRefresh.Request)
    func onDidSelectAction(request: ExploreTokensScene.Event.DidSelectAction.Request)
    func onDidFilter(request: ExploreTokensScene.Event.DidFilter.Request)
    func onViewDidAppear(request: ExploreTokensScene.Event.ViewDidAppear.Request)
    func onViewWillDisappear(request: ExploreTokensScene.Event.ViewWillDisappear.Request)
}

extension ExploreTokensScene {
    typealias BusinessLogic = ExploreTokensBusinessLogic
    
    class Interactor {
        
        private let disposeBag: DisposeBag = DisposeBag()
        private var loadingStatusDisposable: Disposable?
        
        private var sceneModel: Model.SceneModel
        
        private let presenter: PresentationLogic
        private let tokensFetcher: TokensFetcherProtocol
        private let balanceCreator: BalanceCreatorProtocol
        private let applicationEventsController: ApplicationEventsControllerProtocol
        
        private let originalAccountId: String
        
        init(
            presenter: PresentationLogic,
            tokensFetcher: TokensFetcherProtocol,
            balanceCreator: BalanceCreatorProtocol,
            applicationEventsController: ApplicationEventsControllerProtocol,
            originalAccountId: String
            ) {
            
            self.sceneModel = Model.SceneModel(tokens: [], filter: "")
            self.presenter = presenter
            self.tokensFetcher = tokensFetcher
            self.balanceCreator = balanceCreator
            self.applicationEventsController = applicationEventsController
            
            self.originalAccountId = originalAccountId
        }
        
        private func observeTokens() {
            self.tokensFetcher
                .observeTokens()
                .subscribe(onNext: { [weak self] (tokens) in
                    self?.sceneModel.tokens = tokens
                    let response = ExploreTokensScene.Event.TokensDidChange.Response(tokens: tokens)
                    self?.presenter.presentTokensDidChange(response: response)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeErrorStatus() {
            self.tokensFetcher
                .observeErrorStatus()
                .subscribe(onNext: { [weak self] (error) in
                    let response = ExploreTokensScene.Event.Error.Response(error: error)
                    self?.presenter.presentError(response: response)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeApplicationEvents() {
            let observer = ApplicationEventsObserver(
                observer: self,
                appDidEnterBackground: { [weak self] in
                    self?.stopLoadingStatusObserving()
                },
                appWillEnterForeground: { [weak self] in
                    self?.startLoadingStatusObserving()
            })
            self.applicationEventsController.add(observer: observer)
        }
        
        private func stopLoadingStatusObserving() {
            self.loadingStatusDisposable?.dispose()
            
            let response: ExploreTokensScene.Event.LoadingStatusDidChange.Response = .loaded
            self.presenter.presentLoadingStatusDidChange(response: response)
        }
        
        private func startLoadingStatusObserving() {
            self.loadingStatusDisposable?.dispose()
            self.loadingStatusDisposable = self.tokensFetcher
                .observeLoadingStatus()
                .subscribe(onNext: { [weak self] (status) in
                    let response = status
                    self?.presenter.presentLoadingStatusDidChange(response: response)
                })
            self.loadingStatusDisposable?.disposed(by: self.disposeBag)
        }
        
        private func filterTokens() {
            self.tokensFetcher.changeFilter(self.sceneModel.filter)
        }
    }
}

extension ExploreTokensScene.Interactor: ExploreTokensScene.BusinessLogic {
    func onViewDidLoad(request: ExploreTokensScene.Event.ViewDidLoad.Request) {
        self.observeTokens()
        self.observeApplicationEvents()
        self.observeErrorStatus()
    }
    
    func onDidInitiateRefresh(request: ExploreTokensScene.Event.DidInitiateRefresh.Request) {
        self.tokensFetcher.reloadTokens()
    }
    
    func onDidSelectAction(request: ExploreTokensScene.Event.DidSelectAction.Request) {
        let identifier = request.identifier
        guard let token = self.tokensFetcher.tokenForIdentifier(identifier)
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
                completion: { (_) in })
        }
    }
    
    func onDidFilter(request: ExploreTokensScene.Event.DidFilter.Request) {
        self.sceneModel.filter = request.filter
        self.filterTokens()
    }
    
    func onViewDidAppear(request: ExploreTokensScene.Event.ViewDidAppear.Request) {
        self.startLoadingStatusObserving()
    }
    
    func onViewWillDisappear(request: ExploreTokensScene.Event.ViewWillDisappear.Request) {
        self.stopLoadingStatusObserving()
    }
}
