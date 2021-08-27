import Foundation
import RxCocoa
import RxSwift

public protocol QRCodeSceneBusinessLogic {
    
    typealias Event = QRCodeScene.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request)
    func onDidTapShareSync(request: Event.DidTapShareSync.Request)
}

extension QRCodeScene {
    
    public typealias BusinessLogic = QRCodeSceneBusinessLogic
    
    @objc(QRCodeSceneInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = QRCodeScene.Event
        public typealias Model = QRCodeScene.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private var sceneModel: Model.SceneModel
        
        private let dataProvider: DataProviderProtocol
        private let disposeBag: DisposeBag = .init()
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic,
            dataProvider: DataProviderProtocol
        ) {
            
            self.presenter = presenter
            self.dataProvider = dataProvider
            
            self.sceneModel = .init(
                title: dataProvider.title,
                data: dataProvider.data
            )
        }
    }
}

// MARK: - Private methods

private extension QRCodeScene.Interactor {
    
    func observeDataProvider() {
        
        dataProvider
            .observeData()
            .subscribe(onNext: { [weak self] (data) in
                self?.sceneModel.data = data
                self?.presentSceneDidUpdate(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    func presentSceneDidUpdate(animated: Bool) {
        let response: Event.SceneDidUpdate.Response = .init(
            sceneModel: sceneModel,
            animated: animated
        )
        presenter.presentSceneDidUpdate(response: response)
    }

    func presentSceneDidUpdateSync(animated: Bool) {
        let response: Event.SceneDidUpdateSync.Response = .init(
            sceneModel: sceneModel,
            animated: animated
        )
        presenter.presentSceneDidUpdateSync(response: response)
    }
}

// MARK: - BusinessLogic

extension QRCodeScene.Interactor: QRCodeScene.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        observeDataProvider()
    }
    
    public func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request) {
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidTapShareSync(request: Event.DidTapShareSync.Request) {
        let response: Event.DidTapShareSync.Response = .init(
            value: sceneModel.data
        )
        self.presenter.presentDidTapShareSync(response: response)
    }
}
