import Foundation
import RxSwift
import RxCocoa

public protocol SendConfirmationSceneBusinessLogic {
    
    typealias Event = SendConfirmationScene.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request)
    func onDidTapConfirmationSync(request: Event.DidTapConfirmationSync.Request)
}

extension SendConfirmationScene {
    
    public typealias BusinessLogic = SendConfirmationSceneBusinessLogic
    
    @objc(SendConfirmationSceneInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = SendConfirmationScene.Event
        public typealias Model = SendConfirmationScene.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private var sceneModel: Model.SceneModel
        private let paymentProvider: PaymentProviderProtocol
        
        private let disposeBag: DisposeBag = .init()
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic,
            paymentProvider: PaymentProviderProtocol
        ) {
            
            self.presenter = presenter
            self.paymentProvider = paymentProvider
            
            self.sceneModel = .init(
                payment: paymentProvider.payment
            )
        }
    }
}

// MARK: - Private methods

private extension SendConfirmationScene.Interactor {
    
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
    
    func observePayment() {
        paymentProvider
            .observePayment()
            .subscribe(onNext: { [weak self] (payment) in
                self?.sceneModel.payment = payment
                self?.presentSceneDidUpdate(animated: true)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - BusinessLogic

extension SendConfirmationScene.Interactor: SendConfirmationScene.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        observePayment()
    }
    
    public func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request) {
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidTapConfirmationSync(request: Event.DidTapConfirmationSync.Request) {
        let response: Event.DidTapConfirmationSync.Response = .init()
        presenter.presentDidTapConfirmationSync(response: response)
    }
}
