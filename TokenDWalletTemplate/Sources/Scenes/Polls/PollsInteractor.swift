import Foundation
import RxSwift
import RxCocoa

public protocol PollsBusinessLogic {
    typealias Event = Polls.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onAssetSelected(request: Event.AssetSelected.Request)
    func onActionButtonClicked(request: Event.ActionButtonClicked.Request)
    func onChoiceChanged(request: Event.ChoiceChanged.Request)
}

extension Polls {
    public typealias BusinessLogic = PollsBusinessLogic
    
    @objc(PollsInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = Polls.Event
        public typealias Model = Polls.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private var sceneModel: Model.SceneModel
        private let assetsFetcher: AssetsFetcherProtocol
        private let pollsFetcher: PollsFetcherProtocol
        private let voteWorker: VoteWorkerProtocol
        
        private let loadingStatus: BehaviorRelay<Model.LoadingStatus> = BehaviorRelay(value: .loaded)
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic,
            assetsFetcher: AssetsFetcherProtocol,
            pollsFetcher: PollsFetcherProtocol,
            voteWorker: VoteWorkerProtocol
            ) {
            
            self.presenter = presenter
            self.assetsFetcher = assetsFetcher
            self.pollsFetcher = pollsFetcher
            self.voteWorker = voteWorker
            self.sceneModel = Model.SceneModel(
                assets: [],
                selectedAsset: nil,
                polls: []
            )
        }
        
        // MARK: - Private
        
        private func updateScene() {
            guard let selectedAsset = self.sceneModel.selectedAsset else {
                return
            }
            let response = Event.SceneUpdated.Response(
                content: .polls(self.sceneModel.polls),
                selectedAsset: selectedAsset
            )
            self.presenter.presentSceneUpdated(response: response)
        }
        
        // MARK: - Observe
        
        private func observeAssets() {
            self.assetsFetcher
                .observeAssets()
                .subscribe(onNext: { (assets) in
                    self.sceneModel.assets = assets
                    self.updateSelectedAsset()
                    self.updatePolls()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observePolls() {
            self.pollsFetcher
                .observePolls()
                .subscribe(onNext: { [weak self] (polls) in
                    self?.sceneModel.polls = polls
                    self?.updateScene()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeFetcherLoadingStatus() {
            self.pollsFetcher
                .observeLoadingStatus()
                .subscribe(onNext: { [weak self] (status) in
                    self?.loadingStatus.accept(status)
                })
            .disposed(by: self.disposeBag)
        }
        
        private func observeLoadingStatus() {
            self.loadingStatus.subscribe(onNext: { [weak self] (status) in
                self?.presenter.presentLoadingStatusDidChange(response: status)
            })
            .disposed(by: self.disposeBag)
        }
        
        private func updatePolls() {
            guard let selectedAsset = self.sceneModel.selectedAsset else {
                return
            }
            self.pollsFetcher.setOwnerAccountId(ownerAccountId: selectedAsset.ownerAccountId)
        }
        
        private func updateSelectedAsset() {
            if let selectedAsset = self.sceneModel.selectedAsset {
                guard !self.sceneModel.assets.contains(selectedAsset) else {
                    return
                }
                self.selectFirstAsset()
            } else {
                self.selectFirstAsset()
            }
        }
        
        private func selectFirstAsset() {
            self.sceneModel.selectedAsset = self.sceneModel.assets.first
        }
        
        // MARK: - Action handling
        
        private func handleAddVote(pollId: String) {
            guard let poll = self.sceneModel.polls.first(where: { (poll) -> Bool in
                return poll.id == pollId
            }), let currentChoice = poll.currentChoice else {
                return
            }
            self.loadingStatus.accept(.loading)
            self.voteWorker.addVote(
                pollId: pollId,
                choice: currentChoice,
                completion: { [weak self] (result) in
                    self?.loadingStatus.accept(.loaded)
                    switch result {
                    case .failure(let error):
                        let response = Event.Error.Response(error: error)
                        self?.presenter.presentError(response: response)
                        
                    case .success:
                        self?.pollsFetcher.reloadPolls()
                    }
            })
        }
        
        private func handleRemoveVote(pollId: String) {
            self.loadingStatus.accept(.loading)
            self.voteWorker.removeVote(
                pollId: pollId,
                completion: { [weak self] (result) in
                    self?.loadingStatus.accept(.loaded)
                    switch result {
                        
                    case .failure(let error):
                        let response = Event.Error.Response(error: error)
                        self?.presenter.presentError(response: response)
                        
                    case .success:
                        self?.pollsFetcher.reloadPolls()
                    }
            })
        }
    }
}

extension Polls.Interactor: Polls.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        self.observeLoadingStatus()
        self.observeAssets()
        self.observePolls()
        self.observeFetcherLoadingStatus()
    }
    
    public func onAssetSelected(request: Event.AssetSelected.Request) {
        guard let asset = self.sceneModel.assets.first(where: { (asset) -> Bool in
            return asset.ownerAccountId == request.ownerAccountId &&
                asset.code == request.assetCode
        }) else { return }
        
        self.sceneModel.selectedAsset = asset
        self.updatePolls()
    }
    
    public func onActionButtonClicked(request: Event.ActionButtonClicked.Request) {
        switch request.actionType {
            
        case .remove:
            self.handleRemoveVote(pollId: request.pollId)
            
        case .submit:
            self.handleAddVote(pollId: request.pollId)
        }
    }
    
    public func onChoiceChanged(request: Event.ChoiceChanged.Request) {
        guard var poll = self.sceneModel.polls.first(where: { (poll) -> Bool in
            return poll.id == request.pollId
        }),
            let pollIndex = self.sceneModel.polls.indexOf(poll),
            poll.choices.contains(where: { (choice) -> Bool in
                return choice.value == request.choice
            }) else { return }
        
        poll.currentChoice = request.choice
        self.sceneModel.polls[pollIndex] = poll
    }
}
