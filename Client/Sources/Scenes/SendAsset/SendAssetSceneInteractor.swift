import Foundation
import RxSwift
import RxCocoa

public protocol SendAssetSceneBusinessLogic {
    
    typealias Event = SendAssetScene.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request)
    func onDidEnterRecipientSync(request: Event.DidEnterRecipientSync.Request)
    func onDidTapContinueSync(request: Event.DidTapContinueSync.Request)
}

extension SendAssetScene {
    
    public typealias BusinessLogic = SendAssetSceneBusinessLogic
    
    @objc(SendAssetSceneInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = SendAssetScene.Event
        public typealias Model = SendAssetScene.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private var sceneModel: Model.SceneModel
        private let recipientProvider: RecipientProviderProtocol
        
        private let disposeBag: DisposeBag = .init()
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic,
            recipientProvider: RecipientProviderProtocol
        ) {
            
            self.presenter = presenter
            self.recipientProvider = recipientProvider
            
            self.sceneModel = .init(
                recipientAddress: recipientProvider.recipientAddress
            )
        }
    }
}

// MARK: - Private methods

private extension SendAssetScene.Interactor {
    
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
    
    func validateRecipient() -> Model.RecipientValidationError? {
        guard let recipient = sceneModel.recipientAddress,
              !recipient.isEmpty
        else {
            return .emptyString
        }
        
        return nil
    }
    
    func observeRecipient() {
        recipientProvider
            .observeRecipientAddress()
            .subscribe(onNext: { [weak self] (address) in
                
                self?.sceneModel.recipientAddress = address
                self?.presentSceneDidUpdate(animated: false)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - BusinessLogic

extension SendAssetScene.Interactor: SendAssetScene.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        observeRecipient()
    }
    
    public func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request) {
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidEnterRecipientSync(request: Event.DidEnterRecipientSync.Request) {
        sceneModel.recipientAddress = request.value
        sceneModel.recipientError = nil
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidTapContinueSync(request: Event.DidTapContinueSync.Request) {
        
        sceneModel.recipientError = validateRecipient()
        
        guard let recipient = sceneModel.recipientAddress,
              sceneModel.recipientError == nil
        else {
            presentSceneDidUpdateSync(animated: false)
            return
        }
        
        let response: Event.DidTapContinueSync.Response = .init(recipient: recipient)
        presenter.presentDidTapContinueSync(response: response)
    }
}
