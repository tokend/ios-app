import Foundation
import RxSwift
import RxCocoa

protocol DepositSceneBusinessLogic {
    typealias Event = DepositScene.Event
    
    func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request)
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onViewDidLayoutSubviews(request: Event.ViewDidLayoutSubviews.Request)
    func onDidSelectAsset(request: Event.DidSelectAsset.Request)
    func onRenewAddress(request: Event.RenewAddress.Request)
    func onGetAddress(request: Event.GetAddress.Request)
    func onShare(request: Event.Share.Request)
    func onRefresh(request: Event.DidInitiateRefresh.Request)
}

extension DepositScene {
    typealias BusinessLogic = DepositSceneBusinessLogic
    
    class Interactor {
        
        typealias Event = DepositScene.Event
        typealias Model = DepositScene.Model
        
        // MARK: - Private properties
        
        private let queue: DispatchQueue = DispatchQueue(
            label: NSStringFromClass(Interactor.self).queueLabel,
            qos: .userInteractive
        )
        
        private let presenter: PresentationLogic
        private let assetsFetcher: AssetsFetcherProtocol
        private let addressManager: AddressManagerProtocol
        
        private var sceneModel: Model.SceneModel
        
        private let regenerateQrDebounceEvent: BehaviorRelay<Void> = BehaviorRelay(value: ())
        
        private let disposableBag: DisposeBag = DisposeBag()
        
        private var selectedAsset: Model.Asset? {
            return self.assetsFetcher.assetForId(self.sceneModel.selectedAssetId)
        }
        
        init(
            presenter: PresentationLogic,
            assetsFetcher: AssetsFetcherProtocol,
            addressManager: AddressManagerProtocol,
            sceneModel: Model.SceneModel
            ) {
            
            self.presenter = presenter
            self.assetsFetcher = assetsFetcher
            self.addressManager = addressManager
            self.sceneModel = sceneModel
            
            let scheduler = SerialDispatchQueueScheduler(
                queue: self.queue,
                internalSerialQueueName: self.queue.label
            )
            self.regenerateQrDebounceEvent
                .debounce(0.15, scheduler: scheduler)
                .subscribe(onNext: { [weak self] (_) in
                    self?.regenerateQrCodeTask()
                })
                .disposed(by: self.disposableBag)
        }
        
        private func updateSelectedAsset() {
            let selectedId = self.sceneModel.selectedAssetId
            let index: Int? = self.sceneModel.assets.index { (asset) -> Bool in
                return asset.id == selectedId
            }
            if index == nil,
                let asset = self.sceneModel.assets.first {
                
                self.setSelectedAssetId(asset.id)
                self.updateSelectedAsset()
                return
            } else {
                self.assetDidChange()
            }
            
            let response = Event.SelectAsset.Response(index: index)
            self.presenter.presentSelectAsset(response: response)
        }
        
        private func didSelectAsset() {
            self.regenerateQrCode()
            self.assetDidChange()
        }
        
        private func updateAssets() {
            let response = Event.AssetsDidChange.Response(assets: self.sceneModel.assets)
            self.presenter.presentAssetsDidChange(response: response)
        }
        
        private func observeAssets() {
            self.assetsFetcher
                .observeAssets()
                .subscribe(onNext: { [weak self] (assets) in
                    self?.sceneModel.assets = assets
                    self?.updateAssets()
                    self?.updateSelectedAsset()
                })
                .disposed(by: self.disposableBag)
        }
        
        private func observeAssetsLoadingStatus() {
            self.assetsFetcher
                .observeAssetsLoadingStatus()
                .subscribe(onNext: { [weak self] (status) in
                    let response = Event.Loading.Response(status: status)
                    self?.presenter.presentLoading(response: response)
                })
                .disposed(by: self.disposableBag)
        }
        
        private func observeAssetsErrorStatus() {
            self.assetsFetcher
                .observeAssetsErrorStatus()
                .subscribe(onNext: { [weak self] (error) in
                    let response = Event.Error.Response(error: error)
                    self?.presenter.presentError(response: response)
                })
                .disposed(by: self.disposableBag)
        }
        
        private func setSelectedAssetId(_ id: AssetID) {
            self.sceneModel.selectedAssetId = id
            self.didSelectAsset()
        }
        
        private func regenerateQrCode() {
            self.regenerateQrDebounceEvent.emitEvent()
        }
        
        private func assetDidChange() {
            let optionalAsset = self.selectedAsset
            let renewStatus: Event.AssetDidChange.RenewStatus = {
                let canRenew: Bool = optionalAsset?.isRenewable ?? false
                let isRenewing = optionalAsset?.isRenewing ?? false
                if canRenew {
                    if isRenewing {
                        return .renewing
                    } else {
                        return .renewable
                    }
                } else {
                    return .notRenewable
                }
            }()
            let response = Event.AssetDidChange.Response(
                asset: optionalAsset,
                renewStatus: renewStatus,
                canShare: optionalAsset?.address != nil
            )
            self.presenter.presentAssetDidChange(response: response)
        }
        
        private func regenerateQrCodeTask() {
            let data: String? = self.selectedAsset?.address
            
            let response = Event.QRDidChange.Response(
                data: data,
                size: self.sceneModel.qrCodeSize
            )
            self.presenter.presentQRDidChange(response: response)
        }
    }
}

extension DepositScene.Interactor: DepositScene.BusinessLogic {
    func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request) {
        self.sceneModel.assets = self.assetsFetcher.assets
        let index = self.sceneModel.assets.first == nil ? nil : 0
        let response = Event.ViewDidLoadSync.Response(
            assets: self.sceneModel.assets,
            selectedAssetIndex: index
        )
        if self.sceneModel.selectedAssetId == "",
            let id = self.sceneModel.assets.first?.id {
            self.setSelectedAssetId(id)
        }
        self.presenter.presentViewDidLoadSync(response: response)
    }
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        self.observeAssets()
        self.observeAssetsErrorStatus()
        self.observeAssetsLoadingStatus()
    }
    
    func onViewDidLayoutSubviews(request: Event.ViewDidLayoutSubviews.Request) {
        self.sceneModel.qrCodeSize = request.qrCodeSize
        self.regenerateQrCode()
    }
    
    func onDidSelectAsset(request: Event.DidSelectAsset.Request) {
        self.setSelectedAssetId(request.id)
    }
    
    func onGetAddress(request: Event.GetAddress.Request) {
        if let asset = self.selectedAsset {
            self.addressManager.bindAddressForAsset(asset: asset.asset, externalSystemType: asset.externalSystemType)
        }
    }
    
    func onRenewAddress(request: Event.RenewAddress.Request) {
        if let asset = self.selectedAsset {
            self.addressManager.renewAddressForAsset(asset: asset.asset, externalSystemType: asset.externalSystemType)
        }
    }
    
    func onShare(request: Event.Share.Request) {
        
        guard let selectedAssetAddress = self.selectedAsset?.address else {
            return
        }
        let items: [Any] = [selectedAssetAddress]
        let response = Event.Share.Response(
            items: items
        )
        self.presenter.presentShare(response: response)
    }
    
    func onRefresh(request: Event.DidInitiateRefresh.Request) {
        self.assetsFetcher.refreshAssets()
    }
}
