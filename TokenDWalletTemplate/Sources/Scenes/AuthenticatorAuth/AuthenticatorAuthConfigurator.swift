import Foundation

extension AuthenticatorAuth {
    
    enum Configurator {
        static func configure(
            viewController: ViewController,
            appController: AppControllerProtocol,
            sceneModel: Model.SceneModel,
            authRequestWorker: AuthRequestWorkerProtocol,
            authAppAvailibilityChecker: AuthAppAvailibilityCheckerProtocol,
            authRequestKeyFetcher: AuthRequestKeyFectherProtocol,
            qrCodeGenerator: AuthRequestQRCodeGeneratorProtocol,
            authRequestBuilder: AuthRequestBuilderProtocol,
            downloadUrlFetcher: DownloadUrlFetcherProtocol,
            routing: Routing?,
            onDeinit: DeinitCompletion = nil
            ) {
            
            let presenterDispatch = PresenterDispatch(displayLogic: viewController)
            let presenter = Presenter(
                presenterDispatch: presenterDispatch,
                qrCodeGenerator: qrCodeGenerator
            )
            let interactor = Interactor(
                presenter: presenter,
                appController: appController,
                sceneModel: sceneModel,
                authRequestWorker: authRequestWorker,
                authAppAvailibilityChecker: authAppAvailibilityChecker,
                authRequestKeyFetcher: authRequestKeyFetcher,
                authRequestBuilder: authRequestBuilder,
                downloadUrlFetcher: downloadUrlFetcher
            )
            let interactorDispatch = InteractorDispatch(businessLogic: interactor)
            viewController.inject(
                interactorDispatch: interactorDispatch,
                routing: routing,
                onDeinit: onDeinit
            )
        }
    }
}

extension AuthenticatorAuth {
    
    class InteractorDispatch {
        
        private let queue: DispatchQueue = DispatchQueue(
            label: "\(NSStringFromClass(InteractorDispatch.self))\(BusinessLogic.self)".queueLabel,
            qos: .userInteractive
        )
        
        private let businessLogic: BusinessLogic
        
        init(businessLogic: BusinessLogic) {
            self.businessLogic = businessLogic
        }
        
        func sendRequest(requestBlock: @escaping (_ businessLogic: BusinessLogic) -> Void) {
            self.queue.async {
                requestBlock(self.businessLogic)
            }
        }
        
        func sendSyncRequest<ReturnType: Any>(
            requestBlock: @escaping (_ businessLogic: BusinessLogic) -> ReturnType
            ) -> ReturnType {
            return requestBlock(self.businessLogic)
        }
    }
    
    class PresenterDispatch {
        
        private weak var displayLogic: DisplayLogic?
        
        init(displayLogic: DisplayLogic) {
            self.displayLogic = displayLogic
        }
        
        func display(displayBlock: @escaping (_ displayLogic: DisplayLogic) -> Void) {
            guard let displayLogic = self.displayLogic else { return }
            
            DispatchQueue.main.async {
                displayBlock(displayLogic)
            }
        }
        
        func displaySync(displayBlock: @escaping (_ displayLogic: DisplayLogic) -> Void) {
            guard let displayLogic = self.displayLogic else { return }
            
            displayBlock(displayLogic)
        }
    }
}
