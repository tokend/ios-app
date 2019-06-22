import Foundation
import RxSwift

public protocol PollsBusinessLogic {
    typealias Event = Polls.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onAssetSelected(request: Event.AssetSelected.Request)
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
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic,
            assetsFetcher: AssetsFetcherProtocol,
            pollsFetcher: PollsFetcherProtocol
            ) {
            
            self.presenter = presenter
            self.assetsFetcher = assetsFetcher
            self.pollsFetcher = pollsFetcher
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
                polls: self.sceneModel.polls,
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
    }
}

extension Polls.Interactor: Polls.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        self.observeAssets()
        self.observePolls()
    }
    
    public func onAssetSelected(request: Event.AssetSelected.Request) {
        guard let asset = self.sceneModel.assets.first(where: { (asset) -> Bool in
            return asset.ownerAccountId == request.ownerAccountId
        }) else { return }
        
        self.sceneModel.selectedAsset = asset
        self.updatePolls()
    }
}
