import UIKit

protocol DepositScenePresentationLogic {
    typealias Event = DepositScene.Event

    func presentViewDidLoadSync(response: Event.ViewDidLoadSync.Response)
    func presentAssetsDidChange(response: Event.AssetsDidChange.Response)
    func presentSelectAsset(response: Event.SelectAsset.Response)
    func presentQRDidChange(response: Event.QRDidChange.Response)
    func presentAssetDidChange(response: Event.AssetDidChange.Response)
    func presentShare(response: Event.Share.Response)
    func presentError(response: Event.Error.Response)
    func presentLoading(response: Event.Loading.Response)
}

extension DepositScene {
    typealias PresentationLogic = DepositScenePresentationLogic
    
    class Presenter {
        
        typealias Event = DepositScene.Event
        typealias Model = DepositScene.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        private let qrCodeGenerator: QRCodeGeneratorProtocol
        private let dateFormatter: DateFormatterProtocol
        private let errorFormatter: ErrorFormatterProtocol
        
        init(
            presenterDispatch: PresenterDispatch,
            qrCodeGenerator: QRCodeGeneratorProtocol,
            dateFormatter: DateFormatterProtocol,
            errorFormatter: DepositSceneErrorFormatterProtocol
            ) {
            
            self.presenterDispatch = presenterDispatch
            self.qrCodeGenerator = qrCodeGenerator
            self.dateFormatter = dateFormatter
            self.errorFormatter = errorFormatter
        }
        
        private func assetsDidChangeViewModel(
            from assets: [Model.Asset]
            ) -> Event.AssetsDidChange.ViewModel {
            
            typealias Asset = Model.AssetViewModel
            let assets = assets.map { (asset) -> Asset in
                return Asset(
                    id: asset.id,
                    asset: asset.asset
                )
            }
            let viewModel: Event.AssetsDidChange.ViewModel = {
                if assets.isEmpty {
                    return .empty(Localized(.no_assets_can_be_deposited))
                } else {
                    return .assets(assets)
                }
            }()
            return viewModel
        }
    }
}

extension DepositScene.Presenter: DepositScene.PresentationLogic {
    func presentViewDidLoadSync(response: Event.ViewDidLoadSync.Response) {
        let assetsViewModel = self.assetsDidChangeViewModel(from: response.assets)
        let viewModel = Event.ViewDidLoadSync.ViewModel(
            assets: assetsViewModel,
            selectedAssetIndex: response.selectedAssetIndex
        )
        
        self.presenterDispatch.displaySync { (displayLogic) in
            displayLogic.displayViewDidLoadSync(viewModel: viewModel)
        }
    }
    
    func presentAssetsDidChange(response: Event.AssetsDidChange.Response) {
        let viewModel = self.assetsDidChangeViewModel(from: response.assets)
        
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayAssetsDidChange(viewModel: viewModel)
        }
    }
    
    func presentSelectAsset(response: Event.SelectAsset.Response) {
        let viewModel = Event.SelectAsset.ViewModel(index: response.index)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySelectAsset(viewModel: viewModel)
        }
    }
    
    func presentQRDidChange(response: Event.QRDidChange.Response) {
        
        guard let data = response.data
            else {
                self.displayQRDidChange(nil)
                return
        }
        
        self.qrCodeGenerator.generateQRCodeFromString(
            data,
            withTintColor: UIColor.black,
            backgroundColor: UIColor.clear,
            size: response.size,
            completion: { (optionalQrCode) in
                
                guard let qrCode = optionalQrCode
                    else {
                        return
                }
                self.displayQRDidChange(qrCode)
        })
    }
    
    private func displayQRDidChange(_ qrCode: UIImage?) {
        let viewModel = Event.QRDidChange.ViewModel(qrCode: qrCode)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayQRDidChange(viewModel: viewModel)
        }
    }
    
    func presentAssetDidChange(response: Event.AssetDidChange.Response) {
        let viewModel: Event.AssetDidChange.ViewModel
        
        if let asset = response.asset {
            let address: String? = asset.address
            let hint: String = {
                let hintAsset = asset.asset
                if address != nil {
                    var result = Localized(
                        .to_make_a_deposit_send_to_this_address,
                        replace: [
                            .to_make_a_deposit_send_to_this_address_replace_asset: hintAsset
                        ]
                    )

                    if let expirationDate = asset.expirationDate {
                        let date = self.dateFormatter.formatExpiratioDate(expirationDate)
                        result += Localized(
                            .expires_at,
                            replace: [
                                .expires_at_replace_date: date
                            ]
                        )

                    }
                    return result
                } else {
                    return Localized(
                        .no_personal_address,
                        replace: [
                            .no_personal_address_replace_assets_asset: hintAsset
                        ]
                    )

                }
            }()
            let asset = Event.AssetDidChange.ViewModel.Data(
                address: address,
                hint: hint,
                renewStatus: response.renewStatus,
                canShare: response.canShare
            )
            
            if address != nil {
                viewModel = .withAddress(asset)
            } else {
                viewModel = .withoutAddress(asset)
            }
        } else {
            viewModel = .empty(hint: Localized(.this_feature_will_be))
        }
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayAssetDidChange(viewModel: viewModel)
        }
    }
    
    func presentShare(response: Event.Share.Response) {
        self.presenterDispatch.display { (displayLogic) in
            let viewModel = Event.Share.ViewModel(items: response.items)
            displayLogic.displayShare(viewModel: viewModel)
        }
    }
    
    func presentError(response: Event.Error.Response) {
        self.presenterDispatch.display { (displayLogic) in
            let message = self.errorFormatter.getLocalizedDescription(error: response.error)
            let viewModel = Event.Error.ViewModel(message: message)
            displayLogic.displayError(viewModel: viewModel)
        }
    }
    
    func presentLoading(response: Event.Loading.Response) {
        self.presenterDispatch.display { (displayLogic) in
            let viewModel = Event.Loading.ViewModel(status: response.status)
            displayLogic.displayLoading(viewModel: viewModel)
        }
    }
}
