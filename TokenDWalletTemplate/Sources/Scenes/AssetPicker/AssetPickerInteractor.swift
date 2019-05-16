import Foundation
import RxSwift

public protocol AssetPickerBusinessLogic {
    typealias Event = AssetPicker.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onDidFilter(request: Event.DidFilter.Request)
}

extension AssetPicker {
    public typealias BusinessLogic = AssetPickerBusinessLogic
    
    @objc(AssetPickerInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = AssetPicker.Event
        public typealias Model = AssetPicker.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private let assetsFetcher: AssetsFetcherProtocol
        private var sceneModel: Model.SceneModel
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        // MARK: -
        
        init(
            presenter: PresentationLogic,
            assetsFetcher: AssetsFetcherProtocol,
            sceneModel: Model.SceneModel
            ) {
            
            self.presenter = presenter
            self.assetsFetcher = assetsFetcher
            self.sceneModel = sceneModel
        }
        
        // MARK: - Private
        
        private func observeAssets() {
            self.assetsFetcher
                .observeAssets()
                .subscribe(onNext: { (assets) in
                    self.sceneModel.assets = assets
                    self.updateAssets()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func updateAssets() {
            let response: Event.AssetsUpdated.Response
            var assets = self.sceneModel.assets
            if let filter = self.sceneModel.filter,
                !filter.isEmpty {
                
                assets = assets.filter({ (asset) -> Bool in
                    return asset.code.localizedCaseInsensitiveContains(filter)
                })
            }
            if assets.isEmpty {
                response = .empty
            } else {
                response = .assets(assets)
            }
            self.presenter.presentAssetsUpdated(response: response)
        }
    }
}

extension AssetPicker.Interactor: AssetPicker.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        self.observeAssets()
    }
    
    public func onDidFilter(request: Event.DidFilter.Request) {
        self.sceneModel.filter = request.filter
        self.updateAssets()
    }
}
