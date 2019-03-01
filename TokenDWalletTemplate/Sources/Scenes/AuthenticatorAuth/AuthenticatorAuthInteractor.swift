import Foundation

protocol AuthenticatorAuthBusinessLogic {
    typealias Event = AuthenticatorAuth.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onActionButtonClicked(request: Event.ActionButtonClicked.Request)
}

extension AuthenticatorAuth {
    typealias BusinessLogic = AuthenticatorAuthBusinessLogic
    
    class Interactor {
        
        typealias Event = AuthenticatorAuth.Event
        typealias Model = AuthenticatorAuth.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private let appController: AppControllerProtocol
        private var sceneModel: Model.SceneModel
        private let authRequestWorker: AuthRequestWorkerProtocol
        private let authAppAvailibilityChecker: AuthAppAvailibilityCheckerProtocol
        private let authRequestKeyFetcher: AuthRequestKeyFectherProtocol
        private let authRequestBuilder: AuthRequestBuilderProtocol
        private let downloadUrlFetcher: DownloadUrlFetcherProtocol
        
        // MARK: -
        
        init(
            presenter: PresentationLogic,
            appController: AppControllerProtocol,
            sceneModel: Model.SceneModel,
            authRequestWorker: AuthRequestWorkerProtocol,
            authAppAvailibilityChecker: AuthAppAvailibilityCheckerProtocol,
            authRequestKeyFetcher: AuthRequestKeyFectherProtocol,
            authRequestBuilder: AuthRequestBuilderProtocol,
            downloadUrlFetcher: DownloadUrlFetcherProtocol
            ) {
            
            self.presenter = presenter
            self.appController = appController
            self.sceneModel = sceneModel
            self.authRequestWorker = authRequestWorker
            self.authAppAvailibilityChecker = authAppAvailibilityChecker
            self.authRequestKeyFetcher = authRequestKeyFetcher
            self.authRequestBuilder = authRequestBuilder
            self.downloadUrlFetcher = downloadUrlFetcher
        }
        
        // MARK: - Private
        
        private func setupActionButton() {
            DispatchQueue.main.async {
                let state: Model.AuthAppStateModel = {
                    if self.authAppAvailibilityChecker.isAppAvailable() {
                        return .installed
                    } else {
                        let downloadUrl = self.downloadUrlFetcher.fetchUrl()
                        return downloadUrl == nil ? .cantInstall : .notInstalled
                    }
                }()
                
                let response = Event.SetupActionButton.Resposne(state: state)
                self.presenter.presentSetupActionButton(response: response)
            }
        }
        
        private func updateQRContent() {
            guard let publicKey = self.authRequestKeyFetcher.getPublicKey(),
                let url = self.authRequestBuilder.build(publicKey: publicKey) else {
                    return
            }
            
            self.sceneModel.publicKey = publicKey
            let response = Event.UpdateQRContent.Response(
                url: url,
                qrSize: self.sceneModel.qrSize
            )
            self.presenter.presentUpdateQRContent(response: response)
        }
        
        private func pollAuthResult() {
            guard let key = self.authRequestKeyFetcher.getKey() else {
                return
            }
            self.authRequestWorker.pollAuthResult(
                key: key,
                completion: { [weak self] (result) in
                    switch result {
                        
                    case .failure(let message):
                        let response = Event.FetchedAuthResult.Response(result: .failure(message))
                        self?.presenter.presentFetchedAuthResult(response: response)
                        
                    case .success(let account):
                        let response = Event.FetchedAuthResult.Response(result: .success(account: account))
                        self?.presenter.presentFetchedAuthResult(response: response)
                    }
            })
        }
    }
}

extension AuthenticatorAuth.Interactor: AuthenticatorAuth.BusinessLogic {
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        let openUrlHandler = OpenURLSubscriber.init(
            responder: self,
            handleOpenURL: { [weak self] (url, components, _) -> Bool in
                guard let strongSelf = self else {
                    return false
                }
                return strongSelf.authRequestWorker.handleUrl(url: url, components: components)
        })
        
        self.appController.addOpenURL(subscriber: openUrlHandler)
        
        self.sceneModel.qrSize = request.qrSize
        self.setupActionButton()
        self.updateQRContent()
        self.pollAuthResult()
    }
    
    func onActionButtonClicked(request: Event.ActionButtonClicked.Request) {
        DispatchQueue.main.async { [weak self] in
            let url: URL? = {
                guard let strongSelf = self else {
                    return nil
                }
                if strongSelf.authAppAvailibilityChecker.isAppAvailable() {
                    guard let publicKey = strongSelf.sceneModel.publicKey else {
                        return nil
                    }
                    return strongSelf.authRequestBuilder.build(publicKey: publicKey)
                } else {
                    return strongSelf.downloadUrlFetcher.fetchUrl()
                }
            }()
            
            let response = Event.ActionButtonClicked.Response(url: url)
            self?.presenter.presentActionButtonClicked(response: response)
        }
    }
}
