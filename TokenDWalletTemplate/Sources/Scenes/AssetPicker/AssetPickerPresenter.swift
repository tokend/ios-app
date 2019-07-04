import Foundation

public protocol AssetPickerPresentationLogic {
    typealias Event = AssetPicker.Event
    
    func presentAssetsUpdated(response: Event.AssetsUpdated.Response)
}

extension AssetPicker {
    public typealias PresentationLogic = AssetPickerPresentationLogic
    
    @objc(AssetPickerPresenter)
    public class Presenter: NSObject {
        
        public typealias Event = AssetPicker.Event
        public typealias Model = AssetPicker.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        private let amountFormatter: AmountFormatterProtocol
        
        // MARK: -
        
        init(
            presenterDispatch: PresenterDispatch,
            amountFormatter: AmountFormatterProtocol
            ) {
            
            self.presenterDispatch = presenterDispatch
            self.amountFormatter = amountFormatter
        }
    }
}

extension AssetPicker.Presenter: AssetPicker.PresentationLogic {
    
    public func presentAssetsUpdated(response: Event.AssetsUpdated.Response) {
        let viewModel: Event.AssetsUpdated.ViewModel
        switch response {
            
        case .assets(let models):
            let assets = models.map { (asset) -> AssetPicker.AssetCell.ViewModel in
                let firstLetter = asset.code.first?.description ?? ""
                var imageRepresentation = Model.ImageRepresentation.abbreviation
                if let url = asset.iconUrl {
                    imageRepresentation = .image(url)
                }
                return AssetPicker.AssetCell.ViewModel(
                    code: asset.code,
                    imageRepresentation: imageRepresentation,
                    abbreviationBackgroundColor: TokenColoringProvider.shared.coloringForCode(asset.code),
                    abbreviationText: firstLetter,
                    ownerAccountId: asset.ownerAccountId
                )
            }
            viewModel = .assets(assets)
            
        case .empty:
            viewModel = .empty
        }
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayAssetsUpdated(viewModel: viewModel)
        }
    }
}
