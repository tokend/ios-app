import Foundation
import UIKit

protocol SaleInfoPresentationLogic {
    func presentTabsUpdated(response: SaleInfo.Event.OnTabsUpdated.Response)
    func presentTabDidChange(response: SaleInfo.Event.TabDidChange.Response)
}

extension SaleInfo {
    typealias PresentationLogic = SaleInfoPresentationLogic
    typealias DateFormatter = TransactionDetails.DateFormatter
    typealias AmountFormatter = SharedAmountFormatter
    
    struct Presenter {
        
        private let presenterDispatch: PresenterDispatch
        private let dateFormatter: SaleInfo.DateFormatter
        private let amountFormatter: SaleInfo.AmountFormatter
        private let textFormatter: SaleInfoTextFormatterProtocol
        
        init(
            presenterDispatch: PresenterDispatch,
            dateFormatter: DateFormatter,
            amountFormatter: AmountFormatter,
            textFormatter: SaleInfoTextFormatterProtocol
            ) {
            
            self.presenterDispatch = presenterDispatch
            self.dateFormatter = dateFormatter
            self.amountFormatter = amountFormatter
            self.textFormatter = textFormatter
        }
        
        private func getPlainTextTabViewModel(
            model: SaleInfo.PlainTextContent.Model
            ) -> SaleInfo.PlainTextContent.ViewModel {
            
            let contentText = self.textFormatter.formatText(text: model.contentText)
            let viewModel = SaleInfo.PlainTextContent.ViewModel(contentText: contentText)
            return viewModel
        }
        
        private func getGeneralTabViewModel(model: GeneralContent.Model) -> GeneralContent.ViewModel {
            let sections: [SaleInfo.GeneralContent.SectionViewModel]
            
            let startTimeCellValue = self.dateFormatter.dateToString(date: model.startTime)
            let startTimeCell = SaleInfo.GeneralContent.TitleValueCellModel(
                title: Localized(.start_time),
                identifier: .startTime,
                value: startTimeCellValue
            )
            
            let closeTimeCellValue = self.dateFormatter.dateToString(date: model.endTime)
            let closeTimeCell = SaleInfo.GeneralContent.TitleValueCellModel(
                title: Localized(.close_time),
                identifier: .closeTime,
                value: closeTimeCellValue
            )
            
            let baseAssetCell = SaleInfo.GeneralContent.TitleValueCellModel(
                title: Localized(.base_asset_for_hard_cap),
                identifier: .baseAsset,
                value: model.defaultQuoteAsset
            )
            
            let softCapCellValue = self.amountFormatter.formatAmount(model.softCap, currency: model.defaultQuoteAsset)
            let softCapCell = SaleInfo.GeneralContent.TitleValueCellModel(
                title: Localized(.soft_cap),
                identifier: .softCap,
                value: softCapCellValue
            )
            
            let hardCapCellValue = self.amountFormatter.formatAmount(model.hardCap, currency: model.defaultQuoteAsset)
            let hardCapCell = SaleInfo.GeneralContent.TitleValueCellModel(
                title: Localized(.hard_cap),
                identifier: .hardCap,
                value: hardCapCellValue
            )
            
            let baseHardCapCell = SaleInfo.GeneralContent.TitleValueCellModel(
                title: model.baseAsset + Localized(.to_sell),
                identifier: .hardCap,
                value: self.amountFormatter.assetAmountToString(model.baseHardCap)
            )
            
            let saleDetailsSection = SaleInfo.GeneralContent.SectionViewModel(
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
            let viewModel = SaleInfo.GeneralContent.ViewModel(sections: sections)
            
            return viewModel
        }
        
        private func getTokenTabViewModel(model: SaleInfo.TokenContent.Model) -> SaleInfo.TokenContent.ViewModel {
            let availableCell = SaleInfo.TokenCellModel(
                title: Localized(.available),
                identifier: .available,
                value: self.amountFormatter.assetAmountToString(model.availableTokenAmount)
            )
            
            let issuedCell = SaleInfo.TokenCellModel(
                title: Localized(.issued),
                identifier: .issued,
                value: self.amountFormatter.assetAmountToString(model.issuedTokenAmount)
            )
            
            let maxCell = SaleInfo.TokenCellModel(
                title: Localized(.maximum),
                identifier: .max,
                value: self.amountFormatter.assetAmountToString(model.maxTokenAmount)
            )
            
            let tokenSummerySections = SaleInfo.SectionViewModel(
                title: Localized(.token_summary),
                cells: [
                    availableCell,
                    issuedCell,
                    maxCell
                ],
                description: nil
            )
            let sections: [SaleInfo.SectionViewModel] = [tokenSummerySections]
            
            var balanceStateImage: UIImage?
            switch model.balanceState {
                
            case .created:
                balanceStateImage = #imageLiteral(resourceName: "Checkmark")
                
            case .notCreated:
                break
            }
            
            let viewModel = SaleInfo.TokenContent.ViewModel(
                assetCode: model.assetCode,
                assetName: model.assetName,
                balanceStateImage: balanceStateImage,
                iconUrl: model.imageUrl,
                sections: sections
            )
            return viewModel
        }
        
        private func getContentViewModel(from contentModel: Any) -> Any {
            let viewModel: Any
            
            if let model = contentModel as? SaleInfo.PlainTextContent.Model {
                viewModel = self.getPlainTextTabViewModel(model: model)
            } else if let model = contentModel as? SaleInfo.GeneralContent.Model {
                viewModel = self.getGeneralTabViewModel(model: model)
            } else if let model = contentModel as? SaleInfo.TokenContent.Model {
                viewModel = self.getTokenTabViewModel(model: model)
            } else if let model = contentModel as? SaleInfo.EmptyContent.Model {
                viewModel = SaleInfo.EmptyContent.ViewModel(message: model.message)
            } else {
                viewModel = SaleInfo.LoadingContent.ViewModel()
            }
            
            return viewModel
        }
    }
}

extension SaleInfo.Presenter: SaleInfo.PresentationLogic {
    
    func presentTabsUpdated(response: SaleInfo.Event.OnTabsUpdated.Response) {
        let contentViewModel = self.getContentViewModel(from: response.contentModel)
        
        let viewModel = SaleInfo.Event.OnTabsUpdated.ViewModel(
            tabTitles: response.tabTitles,
            selectedIndex: response.selectedIndex,
            contentViewModel: contentViewModel
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayTabsUpdated(viewModel: viewModel)
        }
    }
    
    func presentTabDidChange(response: SaleInfo.Event.TabDidChange.Response) {
        let tab = response.tab 
        let contentViewModel = self.getContentViewModel(from: tab.contentModel)
        let tabViewModel = SaleInfo.Model.TabViewModel(
            title: tab.title,
            contentViewModel: contentViewModel
        )
        let viewModel = SaleInfo.Event.TabDidChange.ViewModel(tab: tabViewModel)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayTabDidChange(viewModel: viewModel)
        }
    }
}
