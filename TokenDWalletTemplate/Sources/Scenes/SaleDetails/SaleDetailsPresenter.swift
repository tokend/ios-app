import Foundation
import UIKit

public protocol SaleDetailsPresentationLogic {
    
    func presentTabsUpdated(response: SaleDetails.Event.OnTabsUpdated.Response)
}

extension SaleDetails {
    
    public typealias PresentationLogic = SaleDetailsPresentationLogic
    public typealias DateFormatter = TransactionDetails.DateFormatter
    public typealias AmountFormatter = SharedAmountFormatter
    
    public struct Presenter {
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        private let dateFormatter: SaleDetails.DateFormatter
        private let amountFormatter: SaleDetails.AmountFormatter
        
        // MARK: -
        
        public init(
            presenterDispatch: PresenterDispatch,
            dateFormatter: DateFormatter,
            amountFormatter: AmountFormatter
            ) {
            
            self.presenterDispatch = presenterDispatch
            self.dateFormatter = dateFormatter
            self.amountFormatter = amountFormatter
        }
        
        // MARK: - Private
        
        private func getGeneralTabViewModel(model: GeneralContent.Model) -> GeneralContent.ViewModel {
            let sections: [SaleDetails.GeneralContent.SectionViewModel]
            
            let startTimeCellValue = self.dateFormatter.dateToString(date: model.startTime)
            let startTimeCell = SaleDetails.GeneralContent.TitleValueCellModel(
                title: Localized(.start_time),
                identifier: .startTime,
                value: startTimeCellValue
            )
            
            let closeTimeCellValue = self.dateFormatter.dateToString(date: model.endTime)
            let closeTimeCell = SaleDetails.GeneralContent.TitleValueCellModel(
                title: Localized(.close_time),
                identifier: .closeTime,
                value: closeTimeCellValue
            )
            
            let baseAssetCell = SaleDetails.GeneralContent.TitleValueCellModel(
                title: Localized(.base_asset_for_hard_cap),
                identifier: .baseAsset,
                value: model.defaultQuoteAsset
            )
            
            let softCapCellValue = self.amountFormatter.formatAmount(model.softCap, currency: model.defaultQuoteAsset)
            let softCapCell = SaleDetails.GeneralContent.TitleValueCellModel(
                title: Localized(.soft_cap),
                identifier: .softCap,
                value: softCapCellValue
            )
            
            let hardCapCellValue = self.amountFormatter.formatAmount(model.hardCap, currency: model.defaultQuoteAsset)
            let hardCapCell = SaleDetails.GeneralContent.TitleValueCellModel(
                title: Localized(.hard_cap),
                identifier: .hardCap,
                value: hardCapCellValue
            )
            
            let baseHardCapCell = SaleDetails.GeneralContent.TitleValueCellModel(
                title: model.baseAsset + Localized(.to_sell),
                identifier: .hardCap,
                value: self.amountFormatter.assetAmountToString(model.baseHardCap)
            )
            
            let saleDetailsSection = SaleDetails.GeneralContent.SectionViewModel(
                title: "",
                cells: [
                    startTimeCell,
                    closeTimeCell,
                    baseAssetCell,
                    softCapCell,
                    hardCapCell,
                    baseHardCapCell
                ],
                description: nil
            )
            sections = [saleDetailsSection]
            let viewModel = SaleDetails.GeneralContent.ViewModel(
                title: Localized(.sale_summary),
                sections: sections)
            
            return viewModel
        }
        
        private func getTokenTabViewModel(model: SaleDetails.TokenContent.Model) -> SaleDetails.TokenContent.ViewModel {
            let availableCell = SaleDetails.TokenCellModel(
                title: Localized(.available),
                identifier: .available,
                value: self.amountFormatter.assetAmountToString(model.availableTokenAmount)
            )
            
            let issuedCell = SaleDetails.TokenCellModel(
                title: Localized(.issued),
                identifier: .issued,
                value: self.amountFormatter.assetAmountToString(model.issuedTokenAmount)
            )
            
            let maxCell = SaleDetails.TokenCellModel(
                title: Localized(.maximum),
                identifier: .max,
                value: self.amountFormatter.assetAmountToString(model.maxTokenAmount)
            )
            
            let tokenSummerySections = SaleDetails.SectionViewModel(
                title: Localized(.asset_summary),
                cells: [
                    availableCell,
                    issuedCell,
                    maxCell
                ],
                description: nil
            )
            let sections: [SaleDetails.SectionViewModel] = [tokenSummerySections]
            
            var balanceStateImage: UIImage?
            switch model.balanceState {
                
            case .created:
                balanceStateImage = #imageLiteral(resourceName: "Checkmark")
                
            case .notCreated:
                break
            }
            
            let viewModel = SaleDetails.TokenContent.ViewModel(
                assetCode: model.assetCode,
                assetName: model.assetName,
                balanceStateImage: balanceStateImage,
                iconUrl: model.imageUrl,
                title: Localized(.asset_summary),
                sections: sections
            )
            return viewModel
        }
        
        private func getContentViewModels(from contentModels: [Any]) -> [Any] {
            let viewModels: [Any] = contentModels.map { (contentModel) -> Any in
                let viewModel: Any
                
                if let model = contentModel as? SaleDetails.GeneralContent.Model {
                    viewModel = self.getGeneralTabViewModel(model: model)
                } else if let model = contentModel as? SaleDetails.TokenContent.Model {
                    viewModel = self.getTokenTabViewModel(model: model)
                } else if let model = contentModel as? SaleDetails.EmptyContent.Model {
                    viewModel = SaleDetails.EmptyContent.ViewModel(message: model.message)
                } else {
                    viewModel = SaleDetails.LoadingContent.ViewModel()
                }
                
                return viewModel
            }
            
            return viewModels
        }
    }
}

extension SaleDetails.Presenter: SaleDetails.PresentationLogic {
    
    public func presentTabsUpdated(response: SaleDetails.Event.OnTabsUpdated.Response) {
        let contentViewModels: [Any] = self.getContentViewModels(from: response.contentModels)
        
        let viewModel = SaleDetails.Event.OnTabsUpdated.ViewModel(
            contentViewModels: contentViewModels
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayTabsUpdated(viewModel: viewModel)
        }
    }
}
