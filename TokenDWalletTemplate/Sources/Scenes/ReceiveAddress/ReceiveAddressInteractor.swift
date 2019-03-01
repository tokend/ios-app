import Foundation
import RxCocoa
import RxSwift

protocol ReceiveAddressBusinessLogic {
    func onViewDidLoad(request: ReceiveAddress.Event.ViewDidLoad.Request)
    func onViewDidLoadSync(request: ReceiveAddress.Event.ViewDidLoadSync.Request)
    func onViewWillAppear(request: ReceiveAddress.Event.ViewWillAppear.Request)
    func onViewDidLayoutSubviews(request: ReceiveAddress.Event.ViewDidLayoutSubviews.Request)
    func onCopyAction(request: ReceiveAddress.Event.CopyAction.Request)
    func onShareAction(request: ReceiveAddress.Event.ShareAction.Request)
}

extension ReceiveAddress {
    typealias BusinessLogic = ReceiveAddressBusinessLogic
    
    class Interactor {
        
        private let regenerateQRDebounceEvent: BehaviorRelay<Void> = BehaviorRelay(value: ())
        private let addressManager: AddressManagerProtocol
        private let shareUtil: ShareUtilProtocol
        private let presenter: PresentationLogic
        
        private var sceneModel = ReceiveAddress.Model.SceneModel()
        private let disposeBag: DisposeBag = DisposeBag()
        
        private let queue: DispatchQueue = DispatchQueue(
            label: NSStringFromClass(Interactor.self).queueLabel,
            qos: .userInteractive
        )
        
        init(presenter: PresentationLogic, shareUtil: ShareUtilProtocol, addressManager: AddressManagerProtocol) {
            self.presenter = presenter
            self.shareUtil = shareUtil
            self.addressManager = addressManager
            
            self.regenerateQRDebounceEvent
                .debounce(0.2, scheduler: SerialDispatchQueueScheduler(
                    queue: self.queue,
                    internalSerialQueueName: self.queue.label
                    )
                )
                .asObservable()
                .subscribe(onNext: { [weak self] (_) in
                    self?.passRegenerateResponse()
                })
                .disposed(by: self.disposeBag)
            
            var availableActions: [ReceiveAddress.Model.ValueAction] = []
            if self.shareUtil.canBeCopied {
                availableActions.append(.copy)
            }
            if self.shareUtil.canBeShared {
                availableActions.append(.share)
            }
            self.sceneModel.availableValueActions = availableActions
        }
        
        private func passRegenerateResponse() {
            let response = ReceiveAddress.Event.QRCodeRegenerated.Response(
                address: self.sceneModel.address,
                qrSize: self.sceneModel.qrCodeSize
            )
            self.presenter.presentQRCodeRegenerated(response: response)
        }
        
        private func observeAddressChange() {
            self.addressManager
                .observeAddressChange()
                .subscribe(onNext: { [weak self] (address) in
                    self?.updateAddressIfNeeded(address)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func updateAddressIfNeeded(_ newAddress: Address) {
            guard self.sceneModel.address != newAddress else {
                return
            }
            
            self.sceneModel.address = newAddress
            self.presentValueChanged()
            self.regenerateQR()
        }
        
        private func regenerateQR() {
            self.regenerateQRDebounceEvent.accept(())
        }
        
        private func presentValueChanged() {
            let response = ReceiveAddress.Event.ValueChanged.Response(
                address: self.sceneModel.address,
                availableValueActions: self.sceneModel.availableValueActions
            )
            self.presenter.presentValueChanged(response: response)
        }
    }
}

extension ReceiveAddress.Interactor: ReceiveAddress.BusinessLogic {
    func onViewDidLoad(request: ReceiveAddress.Event.ViewDidLoad.Request) {
        self.observeAddressChange()
    }
    
    func onViewDidLoadSync(request: ReceiveAddress.Event.ViewDidLoadSync.Request) {
        let response = ReceiveAddress.Event.ViewDidLoadSync.Response(
            address: self.addressManager.address
        )
        self.presenter.presentViewDidLoadSync(response: response)
    }
    
    func onViewWillAppear(request: ReceiveAddress.Event.ViewWillAppear.Request) {
        self.updateAddressIfNeeded(self.addressManager.address)
    }
    
    func onViewDidLayoutSubviews(request: ReceiveAddress.Event.ViewDidLayoutSubviews.Request) {
        self.sceneModel.qrCodeSize = request.qrCodeSize
        self.regenerateQR()
    }
    
    func onCopyAction(request: ReceiveAddress.Event.CopyAction.Request) {
        let toCopy = self.shareUtil.stringToCopyAddress(
            self.sceneModel.address
        )
        let response = ReceiveAddress.Event.CopyAction.Response(stringToCopy: toCopy)
        self.presenter.presentCopyAction(response: response)
    }
    
    func onShareAction(request: ReceiveAddress.Event.ShareAction.Request) {
        let toShare = self.shareUtil.itemsToShareAddress(
            self.sceneModel.address
        )
        let response = ReceiveAddress.Event.ShareAction.Response(itemsToShare: toShare)
        self.presenter.presentShareAction(response: response)
    }
}
